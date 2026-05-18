# frozen_string_literal: true

require "rails/railtie"

module Cdek
  class Railtie < Rails::Railtie
    initializer "cdek.set_default_logger" do
      Cdek.configuration.logger ||= Rails.logger
    end
  end
end
