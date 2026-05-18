# frozen_string_literal: true

require_relative "lib/cdek/version"

Gem::Specification.new do |spec|
  spec.name        = "cdek"
  spec.version     = Cdek::VERSION
  spec.authors     = ["Your Name"]
  spec.email       = ["you@example.com"]

  spec.summary     = "Минималистичный Ruby/Rails-клиент для CDEK API v2"
  spec.description = "Тонкий клиент для CDEK API v2 без внешних рантайм-зависимостей: " \
                     "конфигурация, иерархия ошибок, автоматическое управление OAuth2-токеном, " \
                     "интеграция с Rails и установочный генератор."
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.0"

  spec.files = Dir[
    "lib/**/*.rb",
    "README.md",
    "LICENSE",
    "cdek.gemspec"
  ]
  spec.require_paths = ["lib"]

  spec.metadata = {
    "rubygems_mfa_required" => "true"
  }
end
