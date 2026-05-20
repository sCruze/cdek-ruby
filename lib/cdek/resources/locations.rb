# frozen_string_literal: true

module Cdek
  module Resources
    # Справочники локаций CDEK API v2.
    #
    # Тонкая обёртка над эндпоинтами:
    # * GET /location/cities          — список городов
    # * GET /location/regions         — список регионов
    # * GET /location/suggest/cities  — подсказка городов по подстроке
    #
    # Параметры передаются как есть в query-string; обязательной нормализации
    # или валидации не делаем — структура и набор параметров полностью
    # соответствуют официальной документации CDEK. Значения nil автоматически
    # отбрасываются, чтобы не попадать в URL пустыми ключами.
    #
    # Примеры:
    #   Cdek.locations.cities(country_codes: "RU", city: "Москва", size: 5)
    #   Cdek.locations.regions(country_codes: "RU", size: 10)
    #   Cdek.locations.suggest_cities(name: "Моск", country_code: "RU")
    #   Cdek.locations.find_city("Москва")
    class Locations < Base
      CITIES_PATH         = "/location/cities"
      REGIONS_PATH        = "/location/regions"
      SUGGEST_CITIES_PATH = "/location/suggest/cities"

      def cities(params = {})
        client.get(CITIES_PATH, params: params.compact)
      end

      def regions(params = {})
        client.get(REGIONS_PATH, params: params.compact)
      end

      def suggest_cities(params = {})
        client.get(SUGGEST_CITIES_PATH, params: params.compact)
      end

      # Удобный шорткат: найти первый город по точному названию (и стране).
      # Возвращает Hash города или nil, если ничего не нашлось.
      def find_city(name, country_codes: "RU", **extra)
        list = cities({ city: name, country_codes: country_codes, size: 1 }.merge(extra))
        list.is_a?(Array) ? list.first : nil
      end
    end
  end
end
