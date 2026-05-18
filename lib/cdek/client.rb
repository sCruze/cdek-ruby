# frozen_string_literal: true

module Cdek
  # Тонкий клиент-фасад над Cdek::Connection.
  #
  # Реализует «сырые» вызовы CDEK API v2 без дополнительной семантики.
  # Высокоуровневые ресурсы (Calculator, Orders, Locations, Offices, Webhooks)
  # будут добавлены в следующей итерации.
  class Client
    attr_reader :configuration, :connection

    def initialize(configuration = Cdek.configuration)
      @configuration = configuration
      @connection    = Connection.new(configuration)
    end

    def get(path, params: nil, headers: {})
      connection.authenticated_request(:get, path, params: params, headers: headers)
    end

    def post(path, body: nil, headers: {})
      connection.authenticated_request(:post, path, body: body, headers: headers)
    end

    def patch(path, body: nil, headers: {})
      connection.authenticated_request(:patch, path, body: body, headers: headers)
    end

    def put(path, body: nil, headers: {})
      connection.authenticated_request(:put, path, body: body, headers: headers)
    end

    def delete(path, params: nil, headers: {})
      connection.authenticated_request(:delete, path, params: params, headers: headers)
    end

    def reset_token!
      connection.reset_token!
    end
  end
end
