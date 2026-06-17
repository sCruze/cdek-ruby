# frozen_string_literal: true

require "cdek/version"
require "cdek/error"
require "cdek/configuration"
require "cdek/connection"
require "cdek/client"
require "cdek/resources/base"
require "cdek/resources/locations"
require "cdek/resources/deliverypoints"
require "cdek/city_resolver"
require "cdek/city_suggestions"

module Cdek
  CLIENT_MUTEX = Mutex.new
  private_constant :CLIENT_MUTEX

  class << self
    # Возвращает текущий объект конфигурации (создавая его при первом обращении).
    def configuration
      @configuration ||= Configuration.new
    end

    # Блочный синтаксис настройки.
    #
    #   Cdek.configure do |config|
    #     config.account         = ENV["CDEK_ACCOUNT"]
    #     config.secure_password = ENV["CDEK_SECURE_PASSWORD"]
    #     config.production_mode!
    #   end
    def configure
      yield configuration
    end

    # Шареный клиент. Потокобезопасная мемоизация.
    def client
      CLIENT_MUTEX.synchronize { @client ||= Client.new(configuration) }
    end

    # Сбрасывает мемоизированный клиент (полезно после изменения конфигурации
    # или в тестах).
    def reset_client!
      CLIENT_MUTEX.synchronize { @client = nil }
    end

    # Полный сброс — и конфигурации, и клиента.
    def reset!
      CLIENT_MUTEX.synchronize do
        @configuration = nil
        @client        = nil
      end
    end

    # High-level ресурс «Локации» — справочники городов/регионов и suggest.
    # По умолчанию использует шареный Cdek.client; можно передать кастомный
    # клиент (например, в тестах с подменённым transport).
    def locations(custom_client = client)
      Resources::Locations.new(custom_client)
    end

    # High-level ресурс «Пункты выдачи» — список ПВЗ/постаматов по фильтрам.
    def deliverypoints(custom_client = client)
      Resources::Deliverypoints.new(custom_client)
    end

    # CDEK-код города по пользовательскому названию.
    def city_code(name, **options)
      CityResolver.call(name, **options)
    end

    # Нормализованные подсказки городов для autocomplete в хост-приложении.
    def city_suggestions(query, **options)
      CitySuggestions.call(query, **options)
    end
  end
end

# Rails Engine — подключает прокси-эндпоинт, виджет, helper. Подгружаем только
# если хост — Rails-приложение. Версия гема без Rails (standalone скрипты,
# CLI-утилиты) продолжит работать как тонкий клиент API.
require "cdek/engine" if defined?(::Rails::Engine)
