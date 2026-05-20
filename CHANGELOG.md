# Changelog

## 0.3.1

* Дефолтный шаблон `config/initializers/cdek.rb` (создаваемый
  `bin/rails g cdek:install`) переписан: по умолчанию используется
  **боевой** контур API (`config.production_mode!`) — поскольку
  установка гема обычно подразумевает наличие настоящих учётных
  данных, даже если Rails запущен в `development`. Прежнее поведение
  «sandbox в dev/test» приводило к ошибкам авторизации виджета, когда
  в `.env` лежали уже выданные CDEK боевые ключи.
* Для разработки на песочнице добавлен опт-ин через переменную
  окружения `CDEK_SANDBOX=1` (или `true`/`yes`/`on`). При её наличии
  initializer вызывает `config.test_mode!`.
* Из шаблона убран автоматический фолбэк `use_sandbox_credentials!` —
  он маскировал ошибки конфигурации (например, опечатки в названиях
  ENV-переменных). Вызов остался доступным в комментарии для тех,
  кто хочет быстрый старт без своих кредов.

## 0.3.0

* Гем превращён в **монтируемый Rails Engine** (`Cdek::Engine`). Подключается
  одной строкой:

      mount Cdek::Engine, at: "/cdek"

* Добавлен серверный прокси-эндпоинт для официального JS-виджета ПВЗ СДЭК
  (cdek-it/widget v3) — Ruby-аналог `service.php`. Маршрут:
  `GET|POST /cdek/widget_service`. Класс: `Cdek::WidgetServiceController`.

* Вендорный JS-бандл виджета (`@cdek-it/widget@3.11.1`) включён в гем и
  отдаётся через asset pipeline по пути `/assets/cdek/widget.umd.js`.
  Никаких внешних CDN-ссылок: всё работает локально.

* Добавлен view-хелпер `cdek_widget_tag` (модуль `Cdek::WidgetHelper`),
  автоматически подключённый в `ActionController::Base` хост-приложения.
  Рендерит контейнер виджета со всеми data-* атрибутами для Stimulus.

* Генератор `cdek:install` теперь дополнительно копирует Stimulus-контроллер
  `app/javascript/controllers/cdek_widget_controller.js` в хост-приложение.

* Добавлены high-level ресурсы `Cdek.locations` и `Cdek.deliverypoints`
  (перенесены из 0.2.0, остаются без изменений).

### Breaking changes

* `Cdek::Railtie` удалён, заменён на `Cdek::Engine`. Внешний API
  (`Cdek.configure`, `Cdek.client`, ...) — без изменений. Если в проекте
  была явная ссылка на `Cdek::Railtie` (что маловероятно), её нужно убрать.

## 0.2.0

* High-level ресурсы:
  - `Cdek::Resources::Locations` — `cities`, `regions`, `suggest_cities`,
    шорткат `find_city(name, country_codes: "RU")`.
  - `Cdek::Resources::Deliverypoints` — `list`, `pvz_for_city`, `find(code)`.
* Доступ из основного модуля: `Cdek.locations`, `Cdek.deliverypoints`.

## 0.1.0

* Первый релиз: `Cdek.configure`, `Cdek::Client`, OAuth2 client_credentials с
  потокобезопасным кэшем токена, иерархия ошибок (`Cdek::Error`,
  `Cdek::ConfigurationError`, `Cdek::ApiError`), Railtie, генератор `cdek:install`.
