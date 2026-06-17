# cdek

Минималистичный Ruby/Rails-клиент для CDEK API v2 + монтируемый Rails Engine
с виджетом ПВЗ «в коробке». Никаких внешних рантайм-зависимостей.

* OAuth2 client_credentials c потокобезопасным кэшем токена.
* Конфигурация через ENV или Rails-инициализатор.
* High-level ресурсы для частых задач: `Cdek.locations`, `Cdek.deliverypoints`.
* Поиск CDEK-кода города и JSON-подсказки городов для autocomplete.
* **Rails Engine** с прокси-эндпоинтом для официального JS-виджета ПВЗ
  (cdek-it/widget@3).
* Вендорный UMD-бандл виджета — раздаётся через asset pipeline (без CDN).
* View-хелпер `cdek_widget_tag` — вставка виджета одной строкой.

## Установка

```ruby
# Gemfile
gem "cdek"
```

```bash
bundle install
bin/rails generate cdek:install
```

Генератор создаёт:

* `config/initializers/cdek.rb` — заготовку настройки;
* `app/javascript/controllers/cdek_widget_controller.js` — Stimulus-контроллер
  виджета.

Маршрут смонтируйте сами:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount Cdek::Engine, at: "/cdek"
  # ...
end
```

Переменные окружения:

```
CDEK_ACCOUNT=...
CDEK_SECURE_PASSWORD=...
YANDEX_MAPS_API_KEY=...   # ключ Yandex Maps JS API для карты виджета
```

## Использование клиента

```ruby
Cdek.configure do |config|
  config.account         = ENV["CDEK_ACCOUNT"]
  config.secure_password = ENV["CDEK_SECURE_PASSWORD"]
  config.production_mode!   # или config.test_mode! для песочницы
end

# Низкоуровневый вызов:
Cdek.client.get("/deliverypoints", params: { city_code: 44, type: "PVZ" })

# High-level:
moscow = Cdek.locations.find_city("Москва")
points = Cdek.deliverypoints.pvz_for_city(moscow.fetch("code"))

# Город по пользовательскому вводу:
city_code = Cdek.city_code("Москва")
suggestions = Cdek.city_suggestions("мос")
```

## Виджет ПВЗ

В любой view:

```erb
<%= cdek_widget_tag api_key:      ENV["YANDEX_MAPS_API_KEY"],
                    default_city: "Москва",
                    goods:        current_cart.cdek_goods,
                    modal_id:     "cdek-points-modal" %>
```

или в HAML:

```haml
= cdek_widget_tag api_key: ENV["YANDEX_MAPS_API_KEY"],
                  default_city: "Москва",
                  goods: current_cart.cdek_goods,
                  modal_id: "cdek-points-modal"
```


`goods:` должен приходить из хост-приложения. Гем не подставляет
статичный «средний короб», чтобы CDEK не считал доставку по выдуманным
габаритам. Формат одного элемента массива: `width`, `height`, `length`
в сантиметрах, `weight` в граммах. Если в приложении размеры хранятся в
миллиметрах, перед передачей в виджет их нужно перевести в сантиметры;
если вес хранится в килограммах — перевести в граммы.

Что делает хелпер:

1. Рендерит `<div class="cdek-widget">` со всеми data-* для Stimulus.
2. JS-контроллер `cdek-widget` (поставлен генератором) подгружает
   `/assets/cdek/widget.umd.js` (вшитый в гем UMD-бандл) и инициализирует
   `window.CDEKWidget` в root-таргете.
3. Виджет шлёт запросы на `/cdek/widget_service` (Engine route). Если
   `default_city` передан строкой, Stimulus-контроллер добавляет к servicePath
   внутренний параметр `widget_city`, а Engine преобразует его в `city_code`
   перед запросом `/deliverypoints`. Это не даёт виджету загружать все ПВЗ
   страны при открытии карты.
4. На `onChoose` контроллер пишет данные выбранного пункта в скрытые поля
   формы — по умолчанию:

   * `#order_cdek_point_code`
   * `#order_cdek_point_name`
   * `#order_cdek_point_address`
   * `#order_cdek_city_code`

   DOM-id переопределяются именованными аргументами `field_code`,
   `field_name`, `field_address`, `field_city_code` хелпера.

5. Также диспатчится событие `cdek-widget:chosen` с `detail.office` —
   можно слушать в собственных Stimulus-контроллерах.

### Подсказки городов

Engine предоставляет read-only JSON endpoint для autocomplete:

```text
GET /cdek/city_suggestions?q=мос
```

Ответ — массив нормализованных объектов с `code`, `city`, `region`,
`country`, `country_code` и готовым `label`. UI поля ввода, debounce и
выпадающий список остаются на стороне хост-приложения.

### Закрытие модалки

Если виджет встроен в модалку, передайте её `id` в `modal_id:` — после
выбора пункта будет отправлено `document.dispatchEvent(new CustomEvent(
"modal:close", { detail: { id: <modal_id> } }))`. Реализация закрытия —
на стороне хост-приложения (его modal-контроллер слушает это событие).

## Обновление с 0.2.0 → 0.3.0

1. `bundle update cdek`
2. В `config/routes.rb` добавить:

   ```ruby
   mount Cdek::Engine, at: "/cdek"
   ```

3. `bin/rails generate cdek:install` — поставит Stimulus-контроллер.
4. Внешний API (`Cdek.configure`, `Cdek.client`, `Cdek.locations`,
   `Cdek.deliverypoints`) — без изменений.

## Лицензия

MIT.
