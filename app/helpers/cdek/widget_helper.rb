# frozen_string_literal: true

module Cdek
  # Cdek::WidgetHelper — модуль, который Cdek::Engine автоматически подключает
  # ко всем контроллерам хост-приложения. Делает доступным в любой view
  # хелпер `cdek_widget_tag`, который рендерит блок-контейнер для JS-виджета
  # ПВЗ СДЭК со всеми data-* атрибутами для Stimulus.
  module WidgetHelper
    # Рендерит блок-контейнер для JS-виджета. Виджет сам ставит карту,
    # список ПВЗ и фильтры — нам нужно только дать ему div и Yandex-ключ.
    #
    # Параметры (все необязательные):
    #   api_key:           ключ Yandex Maps JS API (по умолчанию — ENV["YANDEX_MAPS_API_KEY"])
    #   default_city:      город «по умолчанию» (например, "Москва" или нечто из cookie)
    #   sender_city:       город отправителя (для расчёта тарифа в виджете)
    #   modal_id:          id модалки-обёртки — для авто-закрытия по выбору пункта
    #   field_*:           DOM-id скрытых input'ов формы заказа, куда писать данные
    #                      о выбранном пункте (по умолчанию совпадают с конвенциями,
    #                      см. README)
    #   label_selector:    CSS-селектор лейбла «Выбран пункт …» (по умолчанию
    #                      `[data-cdek-widget-label]`)
    #   address_selector:  CSS-селектор адреса выбранного пункта (по умолчанию
    #                      `#order_cdek_point_address_view`)
    #   height:            высота контейнера (по умолчанию `"600px"`).
    def cdek_widget_tag(api_key: nil,
                        default_city: "Москва",
                        sender_city: "Москва",
                        modal_id: nil,
                        field_code:      "order_cdek_point_code",
                        field_name:      "order_cdek_point_name",
                        field_address:   "order_cdek_point_address",
                        field_city_code: "order_cdek_city_code",
                        label_selector:    "[data-cdek-widget-label]",
                        address_selector:  "#order_cdek_point_address_view",
                        height: "600px")
      data = cdek_widget_data(
        api_key:          api_key.presence || ENV["YANDEX_MAPS_API_KEY"].to_s,
        default_city:     default_city,
        sender_city:      sender_city,
        service_path:     cdek_engine_widget_service_path,
        script_url:       cdek_widget_asset_path,
        modal_id:         modal_id.to_s,
        field_code:       field_code,
        field_name:       field_name,
        field_address:    field_address,
        field_city_code:  field_city_code,
        label_selector:   label_selector,
        address_selector: address_selector
      )

      # Box-model + position:relative — обязательные условия для корректной
      # отрисовки JS-виджета. Виджет внутри использует absolute-позиционирование
      # для overlay'ев карты, тултипов и поповеров; без позиционированного
      # предка они привязываются к ближайшему позиционированному элементу
      # (часто — корню документа), что выкидывает их визуально за пределы
      # виджета. Поэтому ставим эти стили inline у себя, чтобы хост-приложение
      # ничего дополнительно не требовалось настраивать.
      content_tag :div, class: "cdek-widget",
                        data:  data,
                        style: "display: block; position: relative; width: 100%; " \
                               "height: #{height}; min-height: #{height};" do
        safe_join [
          content_tag(:div, "",
                      class: "cdek-widget__root",
                      data:  { cdek_widget_target: "root" },
                      style: "position: relative; width: 100%; height: 100%;"),
          content_tag(:div, "",
                      class: "cdek-widget__error",
                      data:  { cdek_widget_target: "error" },
                      style: "display: none;")
        ]
      end
    end

    # Хэш data-* атрибутов для Stimulus-контроллера cdek-widget.
    # Ключи в snake_case — Rails сам конвертит "_" в "-" в HTML.
    def cdek_widget_data(api_key:, default_city:, sender_city:, service_path:, script_url:,
                         modal_id:, field_code:, field_name:, field_address:, field_city_code:,
                         label_selector:, address_selector:)
      {
        controller: "cdek-widget",
        cdek_widget_service_path_value:     service_path,
        cdek_widget_script_url_value:       script_url,
        cdek_widget_api_key_value:          api_key,
        cdek_widget_default_location_value: default_city,
        cdek_widget_sender_city_value:      sender_city,
        cdek_widget_modal_id_value:         modal_id,
        cdek_widget_field_code_value:       field_code,
        cdek_widget_field_name_value:       field_name,
        cdek_widget_field_address_value:    field_address,
        cdek_widget_field_city_code_value:  field_city_code,
        cdek_widget_label_selector_value:   label_selector,
        cdek_widget_address_selector_value: address_selector
      }
    end

    # Путь до UMD-бандла виджета, вшитого в гем. Используется JS-контроллером
    # для динамической загрузки скрипта по требованию.
    def cdek_widget_asset_path
      if respond_to?(:asset_path)
        asset_path("cdek/widget.umd.js")
      else
        "/assets/cdek/widget.umd.js"
      end
    end

    # Путь до прокси-эндпоинта из routes engine'а — корректно подхватит mount-точку.
    def cdek_engine_widget_service_path
      Cdek::Engine.routes.url_helpers.widget_service_path
    end
  end
end
