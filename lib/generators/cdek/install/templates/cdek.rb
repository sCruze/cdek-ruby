# frozen_string_literal: true

# Настройка гема Cdek.
#
# Учётные данные удобно хранить в Rails encrypted credentials или ENV.
# В примере ниже используются ENV-переменные.
Cdek.configure do |config|
  config.account         = ENV["CDEK_ACCOUNT"]
  config.secure_password = ENV["CDEK_SECURE_PASSWORD"]

  # Выбор окружения CDEK.
  # * production_mode! — боевой API  https://api.cdek.ru/v2
  # * test_mode!       — песочница   https://api.edu.cdek.ru/v2
  if Rails.env.production?
    config.production_mode!
  else
    config.test_mode!
  end

  # Быстрый старт с публичными тестовыми кредами CDEK (только для песочницы):
  # config.use_sandbox_credentials!

  # Опциональная тонкая настройка:
  # config.timeout      = 15
  # config.open_timeout = 5
  # config.user_agent   = "MyApp/1.0 (+https://example.com)"
  config.logger = Rails.logger

  # Fallback на публичные тестовые креды CDEK, если ENV пустые. Удобно для
  # development/test, чтобы виджет хотя бы открывался без локальной настройки.
  unless config.credentials_present?
    config.use_sandbox_credentials! unless Rails.env.production?
  end
end
