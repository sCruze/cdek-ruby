# frozen_string_literal: true

Cdek::Engine.routes.draw do
  # Прокси для JS-виджета ПВЗ.
  # Виджет шлёт GET (action=offices) и POST (action=calculate) на один URL,
  # поэтому match по обоим методам.
  match "/widget_service",
        to:   "widget_service#call",
        via:  %i[get post],
        as:   :widget_service

  get "/city_suggestions",
      to: "city_suggestions#index",
      as: :city_suggestions
end
