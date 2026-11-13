require "fileutils"
require "json"
require "json_schemer"

module PageMatchers
  MATCHER_DIR = Rails.root.join("tmp/page_matchers")

  module_function

  def record(page_key, matcher)
    return if page_key.blank?

    FileUtils.mkdir_p(MATCHER_DIR)
    path = MATCHER_DIR.join("#{Process.pid}.json")
    entries = File.file?(path) ? JSON.parse(File.read(path)) : []
    entries << { "page" => page_key, "matcher" => matcher }
    File.write(path, JSON.pretty_generate(entries.uniq))
  end

  def page_of(response)
    return response if response.is_a?(Hash)

    JSON.parse(response.body.lstrip.start_with?("{") ? response.body : response.body[/<script[^>]*data-page="app"[^>]*>(.*?)<\/script>/m, 1])
  end

  def schema_path(page_key)
    segments = page_key.to_s.split("/")
    raise ArgumentError, "invalid page key #{page_key.inspect}" if segments.empty? || segments.any? { |segment| segment.empty? || %w[. ..].include?(segment) }

    module_prefix = page_key.to_s.split("/").first
    engine_key = page_key.to_s.delete_prefix("#{module_prefix}/")
    candidates = [ Rails.root.join("config/contracts/pages", "#{page_key}.json") ] +
                 Rails.root.glob("engines/#{module_prefix}/config/contracts/pages/#{engine_key}.json")
    candidates.find(&:file?) || raise(ArgumentError, "no schema for page #{page_key.inspect}")
  end

  def schemer(page_key)
    schema = JSON.parse(File.read(schema_path(page_key)))
    shared = JSON.parse(Rails.root.join("config/contracts/_shared.json").read)
    JSONSchemer.schema(
      schema,
      ref_resolver: ->(uri) { uri.to_s.start_with?("https://rafelo.local/contracts/_shared.json") ? shared : nil }
    )
  end

  def hrefs(value, out = [])
    case value
    when Hash
      value.each do |key, item|
        if %w[href path].include?(key.to_s) || key.to_s.end_with?("Href")
          out << item if item.is_a?(String) && item.start_with?("/")
        else
          hrefs(item, out)
        end
      end
    when Array
      value.each { |item| hrefs(item, out) }
    end
    out
  end
end

RSpec::Matchers.define :match_page_schema do |page_key = nil|
  match do |response|
    @page = PageMatchers.page_of(response)
    key = page_key || @page["component"]
    @errors = PageMatchers.schemer(key).validate(@page.fetch("props")).map do |error|
      "#{error['data_pointer']}: #{error['type']}"
    end
    PageMatchers.record(key, "match_page_schema")
    @errors.empty?
  end
  failure_message { |response| "page schema failed:\n#{@errors.join("\n")}" }
end

RSpec::Matchers.define :within_budgets do |page_key = nil|
  supports_block_expectations

  match do |block|
    @sql = 0
    @upstreams = Hash.new(0)
    sql_subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      next if %w[SCHEMA TRANSACTION].include?(payload[:name]) || payload[:cached]

      @sql += 1
    end
    upstream_subscriber = ActiveSupport::Notifications.subscribe("upstream.call") do |*, payload|
      @upstreams[payload[:name].to_s] += 1
    end
    block.call
    budget = YAML.load_file(Rails.root.join("config/budgets.yml")).fetch("defaults")
    @limits = [ budget.fetch("sql_queries_per_request"), budget.fetch("upstream_calls_per_request") ]
    PageMatchers.record(page_key, "within_budgets") if page_key
    @sql <= @limits[0] && @upstreams.all? { |name, count| count <= budget.fetch("upstream_calls_per_request").fetch(name.to_sym, 0) }
  ensure
    ActiveSupport::Notifications.unsubscribe(sql_subscriber) if sql_subscriber
    ActiveSupport::Notifications.unsubscribe(upstream_subscriber) if upstream_subscriber
  end

  failure_message do
    "budget exceeded: sql=#{@sql}/#{@limits&.first}, upstream=#{@upstreams.inspect}"
  end
end

RSpec::Matchers.define :be_within_props_budget do |page_key = nil|
  match do |response|
    @page = PageMatchers.page_of(response)
    key = page_key || @page["component"]
    @bytes = @page.fetch("props").to_json.bytesize
    @limit = YAML.load_file(Rails.root.join("config/budgets.yml")).dig("defaults", "props_bytes")
    PageMatchers.record(key, "be_within_props_budget")
    @bytes <= @limit
  end
  failure_message { "props are #{@bytes} bytes, over #{@limit}" }
end

RSpec::Matchers.define :have_resolvable_hrefs do |page_key = nil|
  match do |response|
    @page = PageMatchers.page_of(response)
    key = page_key || @page["component"]
    @hrefs = PageMatchers.hrefs(@page.fetch("props")).uniq
    @unresolved = @hrefs.reject do |href|
      path = href.split("?", 2).first
      Rails.application.routes.recognize_path(path, method: :get)
      true
    rescue ActionController::RoutingError
      false
    end
    PageMatchers.record(key, "have_resolvable_hrefs")
    @unresolved.empty?
  end
  failure_message { "unresolvable hrefs: #{@unresolved.inspect}" }
end

RSpec::Matchers.define :match_policy_capabilities do |page_key = nil|
  match do |response|
    @page = PageMatchers.page_of(response)
    key = page_key || @page["component"]
    @can = @page.dig("props", "can") || {}
    @bad = @can.reject do |_name, entry|
      entry.is_a?(Hash) && [ true, false ].include?(entry["allowed"]) &&
        (entry["allowed"] ? entry["reason"].nil? : %w[forbidden disabled].include?(entry["reason"]))
    end
    PageMatchers.record(key, "match_policy_capabilities")
    @bad.empty?
  end
  failure_message { "capabilities do not match their policy shape: #{@bad.inspect}" }
end
