# frozen_string_literal: true

module Cdek
  module Resources
    # Базовый класс для high-level ресурсов CDEK API.
    #
    # Хранит ссылку на клиент. Конкретные ресурсы (Locations, Deliverypoints
    # и т.п.) наследуются и проксируют вызовы в client.get/post/...
    class Base
      attr_reader :client

      def initialize(client = Cdek.client)
        @client = client
      end
    end
  end
end
