# Changelog

## 0.3.4

* **Критический фикс шаблона Stimulus-контроллера** в
  `lib/generators/cdek/install/templates/cdek_widget_controller.js`.
  Виджет `@cdek-it/widget@3` (UMD-бандл, который мы шипим локально)
  ожидает параметр `root` как **строковый id DOM-элемента**, не как сам
  HTMLElement. Внутри он вызывает `document.getElementById(params.root)`.
  Если передать туда объект — getElementById возвращает null, виджет
  безмолвно создаёт «висячий» div с className равным `"[object HTMLDivElement]"`
  и работает с ним вне страницы. Симптомы: запросы к servicePath идут
  200 OK, авторизация в CDEK проходит, но UI виджета не появляется
  в нашем root-таргете — он висит в document.body отдельным узлом.

  Новый шаблон перед `new CDEKWidget(...)` гарантирует уникальный id
  на root-таргете и передаёт виджету именно строку.

  Если ты уже устанавливал гем ранее и Stimulus-контроллер живёт в
  `app/javascript/controllers/cdek_widget_controller.js` твоего проекта —
  обнови файл вручную или перезапусти генератор с флагом `--force`:

      bin/rails generate cdek:install --force

  (`--force` затрёт локальные правки в этом файле и в
  `config/initializers/cdek.rb` — будь осторожен.)

## 0.3.3

* Откат flex-лейаута контейнера виджета, введённого в 0.3.2. Хелпер
  `cdek_widget_tag` снова рендерит обычную box-model:
  внешний `.cdek-widget` — `display: block; width: 100%; height: <height>;`,
  root — `width: 100%; height: 100%;`.

## 0.3.2

* Хелпер `cdek_widget_tag` теперь рендерит контейнер как flex-column с
  явной высотой, а root-элемент виджета — c `flex: 1 1 auto; min-height: 0`.
  **Замечание:** в 0.3.3 этот подход откачен.

## 0.3.1

* Дефолтный шаблон `config/initializers/cdek.rb` переписан: по
  умолчанию используется боевой контур API (`config.production_mode!`).
  Опт-ин на песочницу — через `ENV["CDEK_SANDBOX"]`.

## 0.3.0

* Гем превращён в монтируемый Rails Engine (`Cdek::Engine`).
* Серверный прокси `Cdek::WidgetServiceController` для официального
  JS-виджета ПВЗ СДЭК (Ruby-аналог service.php).
* Вендорный UMD-бандл `@cdek-it/widget@3.11.1` отдаётся через
  asset pipeline по `/assets/cdek/widget.umd.js`.
* View-хелпер `cdek_widget_tag` (`Cdek::WidgetHelper`).
* Генератор `cdek:install` ставит initializer + Stimulus-контроллер.

### Breaking changes

* `Cdek::Railtie` удалён, заменён на `Cdek::Engine`.

## 0.2.0

* High-level ресурсы `Cdek::Resources::Locations` и
  `Cdek::Resources::Deliverypoints`.

## 0.1.0

* Первый релиз: тонкий клиент CDEK API v2, OAuth2, иерархия ошибок,
  Railtie, генератор `cdek:install`.
