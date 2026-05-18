# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module Cdek
  # Низкоуровневый HTTP-коннект к CDEK API.
  #
  # Отвечает за:
  # * получение и кэширование OAuth2 access_token (grant_type=client_credentials);
  # * прозрачный ретрай запроса при 401 (один раз, со сбросом токена);
  # * сериализацию JSON-тел и маппинг HTTP-статусов в иерархию Cdek::ApiError.
  class Connection
    JSON_CONTENT_TYPE     = "application/json"
    FORM_CONTENT_TYPE     = "application/x-www-form-urlencoded"
    TOKEN_PATH            = "/oauth/token"
    TOKEN_REFRESH_LEEWAY  = 30 # секунд до истечения, после которых обновляем заранее

    HTTP_METHOD_CLASSES = {
      get:    Net::HTTP::Get,
      post:   Net::HTTP::Post,
      patch:  Net::HTTP::Patch,
      put:    Net::HTTP::Put,
      delete: Net::HTTP::Delete
    }.freeze

    attr_reader :configuration

    def initialize(configuration)
      @configuration     = configuration
      @token_mutex       = Mutex.new
      @access_token      = nil
      @token_expires_at  = nil
    end

    # Выполняет авторизованный запрос. Любой ответ 2xx — возвращает распарсенное тело.
    # Любая ошибка — поднимается как Cdek::ApiError или его наследник.
    def authenticated_request(method, path, params: nil, body: nil, headers: {})
      execute_authenticated(method, path, params, body, headers, retried: false)
    end

    # Сбрасывает кэшированный токен — следующая операция получит новый.
    def reset_token!
      @token_mutex.synchronize do
        @access_token     = nil
        @token_expires_at = nil
      end
    end

    private

    def execute_authenticated(method, path, params, body, headers, retried:)
      auth_headers = headers.merge("Authorization" => "Bearer #{access_token}")
      raw          = perform(method, path, params: params, body: body, headers: auth_headers)
      outcome      = handle_response(raw)

      if outcome == :reauth
        raise AuthenticationError.new("CDEK: повторный 401 после обновления токена") if retried

        reset_token!
        execute_authenticated(method, path, params, body, headers, retried: true)
      else
        outcome
      end
    end

    def access_token
      @token_mutex.synchronize do
        fetch_token! if token_invalid?
        @access_token
      end
    end

    def token_invalid?
      @access_token.nil? ||
        @token_expires_at.nil? ||
        Time.now >= (@token_expires_at - TOKEN_REFRESH_LEEWAY)
    end

    def fetch_token!
      unless configuration.credentials_present?
        raise ConfigurationError,
              "CDEK: не заданы учётные данные. Установите account и secure_password через Cdek.configure"
      end

      form = URI.encode_www_form(
        grant_type:    "client_credentials",
        client_id:     configuration.account,
        client_secret: configuration.secure_password
      )

      raw    = perform_raw(:post, TOKEN_PATH,
                           body: form,
                           headers: { "Content-Type" => FORM_CONTENT_TYPE, "Accept" => JSON_CONTENT_TYPE })
      parsed = parse_body(raw.body)

      unless raw.is_a?(Net::HTTPSuccess)
        raise AuthenticationError.new(
          "CDEK: не удалось получить access_token",
          status: raw.code.to_i,
          body:   parsed,
          errors: extract_errors(parsed)
        )
      end

      @access_token     = parsed["access_token"]
      @token_expires_at = Time.now + parsed["expires_in"].to_i
    end

    def perform(method, path, params: nil, body: nil, headers: {})
      json_body         = body.nil? ? nil : JSON.generate(body)
      effective_headers = headers.merge(
        "Content-Type" => JSON_CONTENT_TYPE,
        "Accept"       => JSON_CONTENT_TYPE
      )
      perform_raw(method, path, params: params, body: json_body, headers: effective_headers)
    end

    def perform_raw(method, path, params: nil, body: nil, headers: {})
      uri     = build_uri(path, params)
      request = build_request(method, uri, body, headers)
      log_request(method, uri, body)
      execute_http(uri, request).tap { |response| log_response(response) }
    end

    def build_uri(path, params)
      base            = configuration.base_url.to_s.sub(%r{/+\z}, "")
      normalized_path = path.start_with?("/") ? path : "/#{path}"
      URI.parse("#{base}#{normalized_path}").tap do |uri|
        uri.query = URI.encode_www_form(params) if params.is_a?(Hash) && params.any?
      end
    end

    def build_request(method, uri, body, headers)
      klass = HTTP_METHOD_CLASSES.fetch(method) do
        raise ArgumentError, "Неподдерживаемый HTTP-метод: #{method.inspect}"
      end

      klass.new(uri.request_uri).tap do |req|
        headers.each { |key, value| req[key] = value }
        req["User-Agent"] = configuration.user_agent if configuration.user_agent
        req.body = body if body
      end
    end

    def execute_http(uri, request)
      http             = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl     = (uri.scheme == "https")
      http.read_timeout = configuration.timeout
      http.open_timeout = configuration.open_timeout
      http.request(request)
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise TimeoutError, "CDEK: таймаут запроса (#{e.message})"
    rescue SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH, IOError => e
      raise ConnectionError, "CDEK: ошибка соединения (#{e.message})"
    end

    def handle_response(response)
      status = response.code.to_i
      parsed = parse_body(response.body)

      case response
      when Net::HTTPSuccess
        parsed
      when Net::HTTPUnauthorized
        :reauth
      when Net::HTTPBadRequest
        raise BadRequestError.new("CDEK: 400 Bad Request",
                                  status: status, body: parsed, errors: extract_errors(parsed))
      when Net::HTTPNotFound
        raise NotFoundError.new("CDEK: 404 Not Found",
                                status: status, body: parsed, errors: extract_errors(parsed))
      when Net::HTTPTooManyRequests
        raise RateLimitError.new("CDEK: 429 Too Many Requests",
                                 status: status, body: parsed, errors: extract_errors(parsed))
      when Net::HTTPServerError
        raise ServerError.new("CDEK: серверная ошибка #{status}",
                              status: status, body: parsed, errors: extract_errors(parsed))
      else
        raise ApiError.new("CDEK: неожиданный статус #{status}",
                           status: status, body: parsed, errors: extract_errors(parsed))
      end
    end

    def parse_body(body)
      body.nil? || body.to_s.empty? ? {} : JSON.parse(body)
    rescue JSON::ParserError
      { "raw" => body.to_s }
    end

    def extract_errors(parsed)
      parsed.is_a?(Hash) ? parsed["errors"] || parsed["requests"] : nil
    end

    def log_request(method, uri, body)
      configuration.logger&.debug do
        "[CDEK] #{method.to_s.upcase} #{uri} body=#{body && truncate(body)}"
      end
    end

    def log_response(response)
      configuration.logger&.debug { "[CDEK] <- #{response.code} #{truncate(response.body)}" }
    end

    def truncate(text)
      text.to_s[0, 500]
    end
  end
end
