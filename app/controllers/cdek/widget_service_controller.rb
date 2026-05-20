# frozen_string_literal: true

module Cdek
  # Прокси-эндпоинт для JS-виджета ПВЗ СДЭК (cdek-it/widget@3).
  #
  # Виджет ожидает servicePath, который умеет:
  #   * GET  ?action=offices&<фильтры>     -> CDEK API /deliverypoints
  #   * POST {"action":"calculate", ...}   -> CDEK API /calculator/tarifflist
  #
  # Это Ruby-аналог dist/service.php из репозитория cdek-it/widget,
  # построенный поверх нашего тонкого клиента (он же берёт на себя OAuth2 и
  # маппинг ошибок).
  #
  # Эндпоинт публичный read-only — не меняет состояние хост-приложения,
  # авторизация выполняется на нашей стороне CDEK-токенами. CSRF выключен
  # через :null_session, чтобы виджет, не знающий о Rails-токенах, мог делать
  # POST.
  class WidgetServiceController < ::ActionController::Base
    protect_from_forgery with: :null_session

    def call
      cdek_action = cdek_request_action

      case cdek_action
      when "offices"
        render json: Cdek.client.get("/deliverypoints", params: cdek_filtered_params)
      when "calculate"
        render json: Cdek.client.post("/calculator/tarifflist", body: cdek_filtered_params)
      else
        render json: { message: "Unknown action: #{cdek_action.inspect}" }, status: :bad_request
      end
    rescue Cdek::ConfigurationError => e
      render json: { message: e.message }, status: :service_unavailable
    rescue Cdek::ApiError => e
      status = e.status.to_i.positive? ? e.status : 502
      render json: { message: e.message, errors: e.errors, body: e.body }, status: status
    rescue Cdek::Error => e
      render json: { message: e.message }, status: :bad_gateway
    end

    private

      # `action` виджет шлёт либо как query-параметр (GET), либо в JSON-теле (POST).
      def cdek_request_action
        request.query_parameters["action"].presence ||
          request.request_parameters["action"].presence
      end

      # Все параметры запроса, кроме служебных (:action виджета — мы его уже
      # извлекли — и :controller, который добавляет Rails-роутинг). Передаются
      # в CDEK API как есть.
      def cdek_filtered_params
        request.query_parameters
               .merge(request.request_parameters)
               .except("action", "controller")
               .to_h
      end
  end
end
