# Changelog

## 0.3.5

* Хелпер `cdek_widget_tag` теперь добавляет `position: relative` к
  inline-стилям внешнего контейнера `.cdek-widget` и root-элемента
  `.cdek-widget__root`. Это требование самого виджета: внутри он рисует
  overlay'и карты, тултипы и поповеры через `position: absolute`, и без
  позиционированного предка они привязываются к ближайшему
  позиционированному элементу (часто — корню документа) и визуально
  «уезжают» за пределы виджета. Хост-приложениям больше не нужно
  прописывать `position: relative` у себя в CSS.

## 0.3.4

* **Критический фикс шаблона Stimulus-контроллера** в
  `lib/generators/cdek/install/templates/cdek_widget_controller.js`.
  Виджет `@cdek-it/widget@3` ожидает параметр `root` как строковый id,
  не как HTMLElement. Шаблон теперь ставит уникальный id на root-таргет
  и передаёт виджету именно строку. До этого виджет работал «в
  стороне» — запросы офисов проходили 200 OK, но UI не отрисовывался
  в хост-приложении.

## 0.3.3

* Откат flex-лейаута контейнера, введённого в 0.3.2. Box-model
  с явной высотой работает надёжнее.

## 0.3.2

* Попытка перевести контейнер виджета на flex-column. Откачена в 0.3.3.

## 0.3.1

* Дефолтный шаблон `config/initializers/cdek.rb`: production-режим по
  умолчанию; песочница — через `ENV["CDEK_SANDBOX"]`.

## 0.3.0

* Гем превращён в монтируемый Rails Engine (`Cdek::Engine`).
* Серверный прокси `Cdek::WidgetServiceController` для JS-виджета ПВЗ.
* Вендорный UMD-бандл `@cdek-it/widget@3.11.1` через asset pipeline.
* View-хелпер `cdek_widget_tag`.
* Генератор `cdek:install` ставит initializer + Stimulus-контроллер.

### Breaking changes

* `Cdek::Railtie` удалён, заменён на `Cdek::Engine`.

## 0.2.0

* High-level ресурсы `Cdek::Resources::Locations` и
  `Cdek::Resources::Deliverypoints`.

## 0.1.0

* Первый релиз: тонкий клиент CDEK API v2, OAuth2, иерархия ошибок,
  Railtie, генератор `cdek:install`.
