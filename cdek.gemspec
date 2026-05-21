# frozen_string_literal: true

require_relative "lib/cdek/version"

Gem::Specification.new do |spec|
  spec.name        = "cdek"
  spec.version     = Cdek::VERSION
  spec.authors     = ["Sergey Korolyov"]
  spec.email       = ["s.cruze99@yandex.ru"]

  spec.summary     = "Ruby/Rails клиент и Engine для CDEK API v2 с виджетом ПВЗ"
  spec.description = "Тонкий клиент для CDEK API v2 без внешних рантайм-зависимостей: " \
                     "конфигурация, иерархия ошибок, автоматическое управление OAuth2-токеном. " \
                     "Поверх клиента — монтируемый Rails Engine с прокси-эндпоинтом, " \
                     "вендорным JS-виджетом ПВЗ и Stimulus-контроллером."
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.0"

  # Включаем всё содержимое app/, config/ и lib/ (включая шаблоны генератора
  # с расширениями .rb и .js, и вендорный UMD-бандл виджета).
  spec.files = Dir[
    "lib/**/*",
    "app/**/*",
    "config/**/*",
    "README.md",
    "CHANGELOG.md",
    "LICENSE",
    "cdek.gemspec"
  ]
  spec.require_paths = ["lib"]

  spec.metadata = {
    "rubygems_mfa_required" => "true"
  }

  spec.add_development_dependency "rake", "~> 13.0"
end
