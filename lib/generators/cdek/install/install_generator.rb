# frozen_string_literal: true

require "rails/generators/base"

module Cdek
  module Generators
    # bin/rails generate cdek:install
    #
    # Создаёт config/initializers/cdek.rb с шаблоном настройки.
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Создаёт config/initializers/cdek.rb"

      def copy_initializer
        template "cdek.rb", "config/initializers/cdek.rb"
      end
    end
  end
end
