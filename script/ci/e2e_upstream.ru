# frozen_string_literal: true

require "json"

# A small stateful upstream for the example_orders browser journey. It serves
# the committed synthetic fixtures, signs a viewer in with every module grant,
# and keeps one order so an edit can hit a real version conflict.
class E2EUpstream
  ROOT = File.expand_path("../..", __dir__)
  FIXTURES = File.join(ROOT, "engines", "example_orders", "spec", "fixtures", "upstream", "orders")
  CORE_FIXTURES = File.join(ROOT, "engines", "core", "spec", "fixtures", "upstream", "api")

  def initialize
    @mutex = Mutex.new
    reset!
  end

  def call(env)
    request = Rack::Request.new(env)
    path = request.path_info

    case
    when request.get? && path == "/__health"
      json(200, { status: "ok" })
    when request.post? && path == "/__reset"
      reset!
      json(200, { reset: true })
    when request.post? && path == "/__conflict"
      arm_conflict!
      json(200, { conflict: true })
    when request.post? && path == "/auth/sign_in"
      json(200, sign_in_payload)
    when request.get? && path == "/orders"
      json(200, index_payload(request))
    when request.get? && path == "/orders/order-1"
      show_payload
    when request.patch? && path == "/orders/order-1"
      patch_order(request)
    else
      json(404, { error: { code: "not_found" } })
    end
  rescue JSON::ParserError
    json(400, { error: { code: "bad_request" } })
  end

  private

  def reset!
    @mutex.synchronize do
      data = read_json(File.join(FIXTURES, "show.json")).fetch("data")
      @version = data.fetch("version")
      @status = data.fetch("status")
      @customer_name = data.dig("customer", "name")
      @conflict_armed = false
    end
  end

  def arm_conflict!
    @mutex.synchronize { @conflict_armed = true }
  end

  def sign_in_payload
    payload = read_json(File.join(CORE_FIXTURES, "auth", "sign_in.json"))
    grants = read_json(File.join(CORE_FIXTURES, "grants.json")).fetch("grants")
    payload.merge("grants" => grants)
  end

  def index_payload(request)
    payload = read_json(File.join(FIXTURES, "index.json"))
    items = payload.fetch("items")
    status = request.params["status"]
    items = items.select { |item| item["status"] == status } if status && !status.empty?
    page = [ request.params["page"].to_i, 1 ].max

    @mutex.synchronize do
      items = items.map do |item|
        next item unless item["id"] == "order-1"

        item.merge("status" => @status, "version" => @version,
                   "customer" => item.fetch("customer").merge("name" => @customer_name))
      end
      per_page = request.params["per_page"].to_i
      per_page = 25 unless per_page.positive?
      total = items.length
      items = items.slice((page - 1) * per_page, per_page) || []
      payload.merge(
        "items" => items,
        "pagination" => { "total" => total, "page" => page, "per_page" => per_page }
      )
    end
  end

  def show_payload
    @mutex.synchronize { json(200, show_body) }
  end

  def show_body
    data = read_json(File.join(FIXTURES, "show.json")).fetch("data")
    { data: data.merge(
      "status" => @status,
      "version" => @version,
      "customer" => data.fetch("customer").merge("name" => @customer_name)
    ) }
  end

  def patch_order(request)
    body = JSON.parse(request.body.read)
    @mutex.synchronize do
      if_match = request.env["HTTP_IF_MATCH"].to_s
      return conflict if @conflict_armed && if_match == @version.to_s
      return conflict unless if_match == @version.to_s

      @version += 1
      @status = body["status"] if %w[open paid cancelled].include?(body["status"])
      @customer_name = body["customer_name"] if body["customer_name"].is_a?(String) && !body["customer_name"].empty?
      json(200, show_body)
    end
  end

  def conflict
    @conflict_armed = false
    @version += 1
    json(409, { error: { code: "resource.conflict" } })
  end

  def read_json(path)
    JSON.parse(File.read(path))
  end

  def json(status, payload)
    body = JSON.generate(payload)
    [ status, { "content-type" => "application/json", "content-length" => body.bytesize.to_s }, [ body ] ]
  end
end

run E2EUpstream.new
