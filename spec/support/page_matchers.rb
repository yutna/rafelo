require "fileutils"
require "json"
require "json_schemer"

module PageMatchers
  MATCHER_DIR = Rails.root.join("tmp/page_matchers")
  PAGE_KEYS = %w[data meta query pagination can].freeze

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

  def request_env(response)
    response.respond_to?(:request) && response.request ? response.request.env : {}
  end

  def captured_props(response)
    request_env(response)["rafelo.page_props"]
  end

  def built_urls(response)
    request_env(response)["rafelo.urls_built"]
  end

  def path_part(href)
    href.split("?", 2).first.split("#", 2).first
  end

  def component_error(page, page_key)
    return if page_key.blank? || page["component"] == page_key

    "component #{page["component"].inspect} does not match page key #{page_key.inspect}"
  end

  def page_props(page)
    page.fetch("props").slice(*PAGE_KEYS)
  end

  def page_size_errors(props)
    pagination = props["pagination"]
    return [] if pagination.nil?

    maximum = Rafelo::Core::ListQuery.max_per_page
    unless pagination.is_a?(Hash) && pagination["perPage"] == maximum
      return [ "pagination.perPage must equal the ListQuery maximum #{maximum}: #{pagination.inspect}" ]
    end

    items = props.dig("data", "items")
    unless items.is_a?(Array) && items.length == maximum
      return [ "data.items must hold #{maximum} items for a paginated page: #{items.is_a?(Array) ? items.length : items.inspect}" ]
    end

    []
  end

  def capability_errors(props, actual)
    declarations = props.class.declarations
    expected = if declarations.empty?
      {}
    else
      policy = props.class.policy_class.new(
        props.context.viewer,
        permissions: props.context.permissions || Rafelo::Core::PermissionSet.new([])
      )
      Rafelo::Core::CapabilityMap.new(
        policy: policy,
        entries: declarations.values,
        flags: props.context.flags
      ).to_h
    end

    expected = JSON.parse(expected.to_json)
    return [] if actual == expected

    [ "capabilities do not match their policy matrix: expected #{expected.inspect}, got #{actual.inspect}" ]
  end
end

RSpec::Matchers.define :match_page_schema do |page_key = nil|
  match do |response|
    @page = PageMatchers.page_of(response)
    key = page_key || @page["component"]
    @errors = []
    error = PageMatchers.component_error(@page, page_key)
    @errors << error if error
    @errors.concat(PageMatchers.schemer(key).validate(@page.fetch("props")).map do |error|
      "#{error['data_pointer']}: #{error['type']}"
    end)
    PageMatchers.record(key, "match_page_schema")
    @errors.empty?
  end
  failure_message { |_response| "page schema failed:\n#{@errors.join("\n")}" }
end

RSpec::Matchers.define :within_budgets do |page_key = nil|
  supports_block_expectations

  match do |block|
    raise ArgumentError, "within_budgets needs a block" unless block

    @sql = 0
    @upstreams = Hash.new(0)
    @separate = Hash.new(0)
    sql_subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      next if %w[SCHEMA TRANSACTION].include?(payload[:name]) || payload[:cached]

      @sql += 1
    end
    upstream_subscriber = ActiveSupport::Notifications.subscribe("upstream.call") do |*, payload|
      kind = (payload[:kind] || :page).to_sym
      if kind == :page
        @upstreams[payload[:name].to_s] += 1
      else
        @separate[kind] += 1
      end
    end
    block.call
    budget = YAML.load_file(Rails.root.join("config/budgets.yml")).fetch("defaults")
    limits = budget.fetch("upstream_calls_per_request")
    @sql_limit = budget.fetch("sql_queries_per_request")
    PageMatchers.record(page_key, "within_budgets") if page_key
    @sql <= @sql_limit && @upstreams.all? { |name, count| count <= limits.fetch(name, 0) }
  ensure
    ActiveSupport::Notifications.unsubscribe(sql_subscriber) if sql_subscriber
    ActiveSupport::Notifications.unsubscribe(upstream_subscriber) if upstream_subscriber
  end

  failure_message do
    "budget exceeded: sql=#{@sql}/#{@sql_limit}, page upstream=#{@upstreams.inspect}, separate=#{@separate.inspect}"
  end
end

RSpec::Matchers.define :be_within_props_budget do |page_key = nil|
  match do |response|
    @page = PageMatchers.page_of(response)
    key = page_key || @page["component"]
    @errors = []
    @errors << PageMatchers.component_error(@page, page_key) if PageMatchers.component_error(@page, page_key)
    @props = PageMatchers.page_props(@page)
    @bytes = @props.to_json.bytesize
    @limit = YAML.load_file(Rails.root.join("config/budgets.yml")).dig("defaults", "props_bytes")
    @errors << "props are #{@bytes} bytes, over #{@limit}" if @bytes > @limit
    @errors.concat(PageMatchers.page_size_errors(@props))
    PageMatchers.record(key, "be_within_props_budget")
    @errors.empty?
  end

  failure_message { |_response| @errors.join("\n") }
end

RSpec::Matchers.define :have_resolvable_hrefs do |page_key = nil|
  match do |response|
    @page = PageMatchers.page_of(response)
    key = page_key || @page["component"]
    @errors = []
    @errors << PageMatchers.component_error(@page, page_key) if PageMatchers.component_error(@page, page_key)
    @hrefs = PageMatchers.hrefs(@page.fetch("props")).uniq
    @built = PageMatchers.built_urls(response)
    if @built.nil?
      @errors << "no Urls#built capture; render through BaseController#render_page"
    else
      built = @built.map { |href| PageMatchers.path_part(href) }
      @unresolved = @hrefs.reject { |href| built.include?(PageMatchers.path_part(href)) }
      @errors << "unresolvable hrefs: #{@unresolved.inspect}" if @unresolved.any?
    end
    PageMatchers.record(key, "have_resolvable_hrefs")
    @errors.empty?
  end

  failure_message { |_response| @errors.join("\n") }
end

RSpec::Matchers.define :match_policy_capabilities do |page_key = nil|
  match do |response|
    @page = PageMatchers.page_of(response)
    key = page_key || @page["component"]
    @errors = []
    @errors << PageMatchers.component_error(@page, page_key) if PageMatchers.component_error(@page, page_key)
    @can = @page.dig("props", "can") || {}
    props = PageMatchers.captured_props(response)
    if props.nil?
      @errors << "no page props capture; render through BaseController#render_page with a PageProps"
    else
      @errors.concat(PageMatchers.capability_errors(props, @can))
    end
    PageMatchers.record(key, "match_policy_capabilities")
    @errors.empty?
  end

  failure_message { |_response| @errors.join("\n") }
end
