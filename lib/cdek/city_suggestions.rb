# frozen_string_literal: true

module Cdek
  # Builds normalized city suggestions for host application autocomplete UIs.
  class CitySuggestions
    DEFAULT_COUNTRY_CODE = "RU"
    DEFAULT_LIMIT = 10
    MIN_QUERY_LENGTH = 2

    class << self
      def call(query, **options)
        new(query, **options).call
      end
    end

    def initialize(query, client: Cdek.client, country_code: DEFAULT_COUNTRY_CODE, limit: DEFAULT_LIMIT)
      @query = query
      @client = client
      @country_code = country_code
      @limit = limit
    end

    def call
      normalized_query.length < MIN_QUERY_LENGTH ? [] : normalized_suggestions
    end

    private

      attr_reader :query, :client, :country_code, :limit

      def normalized_suggestions
        Array(raw_suggestions).first(limit).filter_map do |city|
          suggestion_payload(city)
        end
      end

      def raw_suggestions
        Cdek.locations(client).suggest_cities(name: normalized_query, country_code: country_code)
      end

      def suggestion_payload(city)
        if city.is_a?(Hash)
          code = city["code"] || city[:code]
          city_name = city["city"] || city[:city] || city["name"] || city[:name]
          region = city["region"] || city[:region]
          country = city["country"] || city[:country]
          country_code_value = city["country_code"] || city[:country_code]

          if code && city_name
            {
              code: code,
              city: city_name,
              region: region,
              country: country,
              country_code: country_code_value,
              label: label_for(city_name, region)
            }
          end
        end
      end

      def label_for(city_name, region)
        [city_name, region].compact.map(&:to_s).reject(&:empty?).uniq.join(", ")
      end

      def normalized_query
        @normalized_query ||= query.to_s.strip
      end
  end
end
