# frozen_string_literal: true

module Cdek
  # Resolves a human-readable city name to a CDEK city code.
  #
  # This is intentionally small and API-backed: host applications can pass
  # user-entered city names to the widget proxy without duplicating lookup
  # logic or loading all delivery points for the whole country.
  class CityResolver
    DEFAULT_COUNTRY_CODES = "RU"
    CACHE_EXPIRES_IN = 43_200

    class << self
      def call(name, **options)
        new(name, **options).call
      end
    end

    def initialize(name, client: Cdek.client, country_codes: DEFAULT_COUNTRY_CODES, cache: default_cache)
      @name = name
      @client = client
      @country_codes = country_codes
      @cache = cache
    end

    def call
      normalized_name.empty? ? nil : cached_city_code
    end

    private

      attr_reader :name, :client, :country_codes, :cache

      def cached_city_code
        if cache
          cache.fetch(cache_key, expires_in: CACHE_EXPIRES_IN) { fetch_city_code }
        else
          fetch_city_code
        end
      end

      def fetch_city_code
        city = Cdek.locations(client).find_city(normalized_name, country_codes: country_codes)

        if city.is_a?(Hash)
          city["code"] || city[:code]
        end
      end

      def normalized_name
        @normalized_name ||= name.to_s.strip
      end

      def cache_key
        ["cdek", "city_code", country_codes, normalized_name.downcase].join(":")
      end

      def default_cache
        if defined?(::Rails) && ::Rails.respond_to?(:cache)
          ::Rails.cache
        end
      end
  end
end
