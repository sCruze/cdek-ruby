# frozen_string_literal: true

# Настройка гема Cdek.
#
# Учётные данные удобно хранить в Rails encrypted credentials или ENV.
# В примере ниже используются ENV-переменные.
Cdek.configure do |config|
  config.account         = ENV["CDEK_ACCOUNT"]
  config.secure_password = ENV["CDEK_SECURE_PASSWORD"]

  # Контур CDEK API. По умолчанию — боевой (api.cdek.ru/v2). С боевыми
  # учётными данными это правильный выбор и в development. Чтобы временно
  # переключиться на песочницу (api.edu.cdek.ru/v2) — добавь в .env:
  #
  #   CDEK_SANDBOX=1
  #
  # либо явно поменяй вызов на config.test_mode!.
  if ENV["CDEK_SANDBOX"].to_s.match?(/\A(1|true|yes|on)\z/i)
    config.test_mode!
  else
    config.production_mode!
  end

  # Опциональная тонкая настройка:
  # config.timeout      = 15
  # config.open_timeout = 5
  # config.user_agent   = "MyApp/1.0 (+https://example.com)"
  config.logger = Rails.logger

  # Быстрый старт с публичными тестовыми кредами CDEK (только для песочницы):
  # config.use_sandbox_credentials!
end
