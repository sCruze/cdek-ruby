# frozen_string_literal: true

module Cdek
  # Public read-only endpoint for city autocomplete in host applications.
  class CitySuggestionsController < ::ActionController::Base
    def index
      render json: Cdek.city_suggestions(
        params[:q],
        country_code: params[:country_code].presence || Cdek::CitySuggestions::DEFAULT_COUNTRY_CODE
      )
    rescue Cdek::ConfigurationError => e
      render json: { message: e.message }, status: :service_unavailable
    rescue Cdek::ApiError => e
      status = e.status.to_i.positive? ? e.status : 502
      render json: { message: e.message, errors: e.errors, body: e.body }, status: status
    rescue Cdek::Error => e
      render json: { message: e.message }, status: :bad_gateway
    end
  end
end
