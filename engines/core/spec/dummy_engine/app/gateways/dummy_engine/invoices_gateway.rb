# frozen_string_literal: true

module DummyEngine
  class InvoicesGateway < Rafelo::Core::Gateway
    upstream :api
    token :viewer

    def find(id)
      client.get("invoices/#{id}")
    end
  end
end
