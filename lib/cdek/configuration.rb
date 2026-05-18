# frozen_string_literal: true

module Cdek
  # Конфигурация гема.
  #
  # Cdek.configure do |config|
  #   config.account         = ENV["CDEK_ACCOUNT"]
  #   config.secure_password = ENV["CDEK_SECURE_PASSWORD"]
  #   config.production_mode!
  # end
  class Configuration
    PRODUCTION_URL = "https://api.cdek.ru/v2"
    TEST_URL       = "https://api.edu.cdek.ru/v2"

    # Тестовые учётные данные CDEK для песочницы публикуются в их документации.
    # Указываются здесь только как ссылка для удобства, ничего не предзаполняется.
    SANDBOX_ACCOUNT          = "EMscd6r9JnFiQ3bLoyjJY6eM78JrJceI"
    SANDBOX_SECURE_PASSWORD  = "PjLZkKBHEiLK3YsHzqYDqQYj1pSwOaNB"

    attr_accessor :account,
                  :secure_password,
                  :base_url,
                  :timeout,
                  :open_timeout,
                  :logger,
                  :user_agent

    def initialize
      @account         = nil
      @secure_password = nil
      @base_url        = TEST_URL
      @timeout         = 15
      @open_timeout    = 5
      @logger          = nil
      @user_agent      = "cdek-ruby/#{Cdek::VERSION}"
    end

    def test_mode!
      @base_url = TEST_URL
    end

    def production_mode!
      @base_url = PRODUCTION_URL
    end

    def use_sandbox_credentials!
      @account         = SANDBOX_ACCOUNT
      @secure_password = SANDBOX_SECURE_PASSWORD
      test_mode!
    end

    def credentials_present?
      account.to_s.strip.length.positive? && secure_password.to_s.strip.length.positive?
    end
  end
end
