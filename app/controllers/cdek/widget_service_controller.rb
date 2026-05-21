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
  # авторизация выполняется на нашей стороне CDEK-токенами. CSRF полностью
  # пропускаем (skip_forgery_protection) — виджет не знает о Rails-токенах,
  # а raise/null_session засоряют логи строкой
  # "Can't verify CSRF token authenticity" на каждый POST виджета.
  #
  # ВАЖНО: wrap_parameters принудительно отключён. По умолчанию Rails для
  # JSON-запросов оборачивает body в ключ, совпадающий с именем контроллера
  # (`widget_service`), и это удваивает все поля запроса. Удвоенные поля
  # утекали в CDEK API как лишний ключ "widget_service" — CDEK его молча
  # игнорировал (200 OK), но логи и сетевой трафик засорялись копией.
  class WidgetServiceController < ::ActionController::Base
    skip_forgery_protection
    wrap_parameters false

    # Имя ключа, под который Rails-обёртка кладёт дубликат параметров,
    # если wrap_parameters всё же сработает (например, при переопределении
    # на уровне ApplicationController наследниками). Удаляется на всякий
    # случай вторым эшелоном защиты.
    WRAPPER_KEY = "widget_service"
    private_constant :WRAPPER_KEY

    # Служебные ключи Rails-роутинга и виджета, которые не должны утечь
    # в тело запроса к CDEK API.
    EXCLUDED_PARAM_KEYS = %w[action controller format].freeze
    private_constant :EXCLUDED_PARAM_KEYS

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

      # Все параметры запроса, кроме служебных Rails-роутинга и Rails-обёртки.
      # Передаются в CDEK API как есть.
      def cdek_filtered_params
        request.query_parameters
               .merge(request.request_parameters)
               .except(*EXCLUDED_PARAM_KEYS, WRAPPER_KEY)
               .to_h
      end
  end
end
