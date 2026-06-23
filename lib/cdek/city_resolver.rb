# frozen_string_literal: true

module Cdek
  # Resolves a human-readable city name to a CDEK city record — both the CDEK
  # city code and the city coordinates — in one API-backed, cached lookup.
  #
  # This is intentionally small and API-backed: host applications can pass
  # user-entered city names to the widget proxy without duplicating lookup
  # logic or loading all delivery points for the whole country. The widget
  # proxy uses #code to filter offices, while the widget helper uses
  # #coordinates to center the map on the chosen city (passing coordinates to
  # the JS widget instead of a name avoids a flaky async geocode that could
  # otherwise drop the map back to its built-in default center).
  class CityResolver
    DEFAULT_COUNTRY_CODES = "RU"
    CACHE_EXPIRES_IN = 43_200

    class << self
      def call(name, **options)
        new(name, **options).code
      end

      def coordinates(name, **options)
        new(name, **options).coordinates
      end
    end

    def initialize(name, client: Cdek.client, country_codes: DEFAULT_COUNTRY_CODES, cache: default_cache)
      @name = name
      @client = client
      @country_codes = country_codes
      @cache = cache
    end

    # CDEK city code or nil when the city can't be resolved.
    def code
      city = cached_city
      city.is_a?(Hash) ? (city["code"] || city[:code]) : nil
    end

    # [longitude, latitude] (floats) or nil when coordinates are unknown.
    # The order matches what the CDEK JS widget expects ([lng, lat]).
    def coordinates
      city = cached_city
      lng = city_coordinate(city, "longitude")
      lat = city_coordinate(city, "latitude")

      (lng && lat) ? [lng, lat] : nil
    end

    private

      attr_reader :name, :client, :country_codes, :cache

      def cached_city
        if normalized_name.empty?
          nil
        elsif cache
          cache.fetch(cache_key, expires_in: CACHE_EXPIRES_IN) { fetch_city }
        else
          fetch_city
        end
      end

      def fetch_city
        Cdek.locations(client).find_city(normalized_name, country_codes: country_codes)
      end

      def city_coordinate(city, key)
        if city.is_a?(Hash)
          raw = city.key?(key) ? city[key] : city[key.to_sym]
          number = Float(raw, exception: false)
          number&.finite? ? number : nil
        end
      end

      def normalized_name
        @normalized_name ||= name.to_s.strip
      end

      def cache_key
        ["cdek", "city", country_codes, normalized_name.downcase].join(":")
      end

      def default_cache
        if defined?(::Rails) && ::Rails.respond_to?(:cache)
          ::Rails.cache
        end
      end
  end
end
