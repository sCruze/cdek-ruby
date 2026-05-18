# frozen_string_literal: true

module Cdek
  # Базовый класс для всех ошибок гема.
  class Error < StandardError; end

  # Ошибка конфигурации (например, отсутствуют креды).
  class ConfigurationError < Error; end

  # Ошибка ответа API. Доступны статус, тело и массив ошибок CDEK.
  class ApiError < Error
    attr_reader :status, :body, :errors

    def initialize(message, status: nil, body: nil, errors: nil)
      super(message)
      @status = status
      @body = body
      @errors = errors
    end
  end

  class AuthenticationError < ApiError; end
  class BadRequestError    < ApiError; end
  class NotFoundError      < ApiError; end
  class RateLimitError     < ApiError; end
  class ServerError        < ApiError; end

  # Ошибки сетевого уровня.
  class ConnectionError < Error; end
  class TimeoutError    < ConnectionError; end
end
