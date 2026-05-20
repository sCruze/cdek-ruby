# frozen_string_literal: true

require "rails/engine"

module Cdek
  # Cdek::Engine — монтируемый Rails Engine, который шипит весь стек интеграции
  # с виджетом ПВЗ СДЭК «в коробке»:
  #
  #   * прокси-эндпоинт   /widget_service  (Cdek::WidgetServiceController)
  #   * вендорный JS      /assets/cdek/widget.umd.js  (через asset pipeline)
  #   * helper для view   cdek_widget_tag (Cdek::WidgetHelper)
  #   * Stimulus-контроллер cdek_widget_controller.js (через генератор cdek:install)
  #
  # Подключение в хост-приложении:
  #
  #   # config/routes.rb
  #   mount Cdek::Engine, at: "/cdek"
  #
  #   # любая view
  #   = cdek_widget_tag api_key: ENV["YANDEX_MAPS_API_KEY"]
  class Engine < ::Rails::Engine
    isolate_namespace Cdek

    # Перенесено из старого Cdek::Railtie — гарантируем, что у конфигурации
    # есть логгер сразу после загрузки приложения.
    initializer "cdek.set_default_logger" do
      Cdek.configuration.logger ||= Rails.logger
    end

    # Asset pipeline (Sprockets / Propshaft) — точечно прекомпилируем UMD-бандл
    # виджета, чтобы он попадал в production-сборку.
    initializer "cdek.assets.precompile" do |app|
      if app.config.respond_to?(:assets) && app.config.assets
        app.config.assets.precompile += %w[cdek/widget.umd.js]
      end
    end

    # Подключаем хелперы гема ко всем контроллерам хост-приложения,
    # чтобы `cdek_widget_tag` был доступен в любой view без явных include.
    initializer "cdek.include_helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper Cdek::WidgetHelper
      end
    end
  end
end
