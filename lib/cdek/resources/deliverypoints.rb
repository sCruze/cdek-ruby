# frozen_string_literal: true

module Cdek
  module Resources
    # Список пунктов выдачи заказов (ПВЗ/Постамат) CDEK API v2.
    # Эндпоинт: GET /deliverypoints
    #
    # Параметры (наиболее часто используемые):
    # * city_code     — код города CDEK (получается через Locations#cities)
    # * postal_code   — почтовый индекс
    # * type          — "PVZ" | "POSTAMAT" | "ALL"
    # * country_code  — двухбуквенный код страны (RU и т.п.)
    # * region_code   — код региона
    # * code          — код конкретного пункта (например MSK2181)
    # * have_cashless / have_cash / allowed_cod / is_dressing_room —
    #                   булевы фильтры
    # * weight_min / weight_max — допустимый вес посылки
    # * is_handout    — выдаёт ли посылки
    # * is_reception  — принимает ли посылки
    # * size / page   — пагинация
    #
    # Возвращает массив пунктов в формате CDEK API (массив Hash).
    #
    # Примеры:
    #   Cdek.deliverypoints.list(city_code: 44, type: "PVZ", size: 100)
    #   Cdek.deliverypoints.pvz_for_city(44)
    #   Cdek.deliverypoints.find("MSK2181")
    class Deliverypoints < Base
      LIST_PATH    = "/deliverypoints"
      DEFAULT_TYPE = "PVZ"

      def list(params = {})
        client.get(LIST_PATH, params: params.compact)
      end

      # Шорткат: ПВЗ по коду города. extra — дополнительные фильтры (например,
      # have_cashless: true), которые мерджатся к city_code и type.
      def pvz_for_city(city_code, extra = {})
        list({ city_code: city_code, type: DEFAULT_TYPE }.merge(extra))
      end

      # Найти конкретный пункт по его коду (CDEK ID, например MSK2181).
      # Возвращает Hash пункта или nil.
      def find(code)
        result = list(code: code, size: 1)
        result.is_a?(Array) ? result.first : nil
      end
    end
  end
end
