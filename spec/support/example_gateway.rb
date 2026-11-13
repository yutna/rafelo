# frozen_string_literal: true

ExampleInvoice = Data.define(:id, :number, :status)

class ExampleInvoicesGateway < Rafelo::Core::Gateway
  upstream :api
  token :viewer

  def find(id)
    payload = JSON.parse(client.get("invoices/#{id}").body).fetch("data")
    ExampleInvoice.new(id: payload.fetch("id").to_s, number: payload.fetch("number"), status: payload.fetch("status"))
  end
end
