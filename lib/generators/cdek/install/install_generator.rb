# frozen_string_literal: true

require "rails/generators/base"

module Cdek
  module Generators
    # bin/rails generate cdek:install
    #
    # Кладёт в хост-приложение:
    #   * config/initializers/cdek.rb                              — настройка гема
    #   * app/javascript/controllers/cdek_widget_controller.js     — Stimulus-контроллер виджета ПВЗ
    #
    # Сам Engine монтируется отдельной строкой в config/routes.rb пользователя:
    #   mount Cdek::Engine, at: "/cdek"
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Создаёт config/initializers/cdek.rb и Stimulus-контроллер виджета ПВЗ."

      def copy_initializer
        template "cdek.rb", "config/initializers/cdek.rb"
      end

      def copy_stimulus_controller
        copy_file "cdek_widget_controller.js",
                  "app/javascript/controllers/cdek_widget_controller.js"
      end

      def print_post_install
        say "\n========================================================================", :green
        say "  Гем Cdek установлен.", :green
        say "========================================================================", :green
        say "  1) Добавьте маршрут в config/routes.rb:"
        say "       mount Cdek::Engine, at: \"/cdek\""
        say ""
        say "  2) Заполните .env (или ENV) переменными:"
        say "       CDEK_ACCOUNT=..."
        say "       CDEK_SECURE_PASSWORD=..."
        say "       YANDEX_MAPS_API_KEY=...   # ключ Yandex Maps JS API для карты виджета"
        say ""
        say "  3) Вставьте виджет в любую view, например в модалку оформления заказа:"
        say "       = cdek_widget_tag api_key: ENV[\"YANDEX_MAPS_API_KEY\"],"
        say "                         default_city: \"Москва\","
        say "                         modal_id: \"cdek-points-modal\""
        say ""
        say "  4) Скрытые поля для приёма выбранного пункта (внутри order_form):"
        say "       order_cdek_point_code"
        say "       order_cdek_point_name"
        say "       order_cdek_point_address"
        say "       order_cdek_city_code"
        say "     (DOM-id можно переопределить аргументами field_* у cdek_widget_tag.)"
        say "========================================================================", :green
      end
    end
  end
end
