# frozen_string_literal: true

require "fileutils"
require "yaml"

# The application template's name rules, payload renderer and initial commit.
# Kept in a plain object so the Rails template and its specs share one
# implementation (GEN-07).
module RafeloTemplate
  RESERVED = %w[
    Core
    DesignSystem
    Rafelo
    Engines
    App
    ExampleOrders
    ExampleCustomers
  ].freeze

  TEMPLATE_AUTHOR_NAME = "Rafelo template"
  TEMPLATE_AUTHOR_EMAIL = "template@rafelo.invalid"

  # The flags GEN-07 requires from `rails new`. The database flag accepts
  # both the short and the long spelling.
  REQUIRED_FLAGS = %w[
    --devcontainer
    --skip-javascript
    --skip-hotwire
    --skip-jbuilder
    --skip-test
  ].freeze

  # Directories and files that never belong to an adopted app.
  DEFAULT_EXCLUDES = %w[
    .git
    .bundle
    node_modules
    tmp
    log
    storage
    test-results
    playwright-report
    blob-report
    coverage
    public/vite
    public/vite-dev
    public/vite-test
  ].freeze

  module_function

  def namespace(app_name)
    app_name.to_s.split(/[_-]/).reject(&:empty?).map do |part|
      part[0].upcase + part[1..].to_s
    end.join
  end

  def reserved?(app_name)
    name = namespace(app_name)
    RESERVED.include?(name) || Object.const_defined?(name)
  end

  def validate!(app_name)
    name = namespace(app_name)
    if RESERVED.include?(name)
      raise ArgumentError, "template: #{app_name.inspect} collides with the reserved namespace #{name}"
    end
    if Object.const_defined?(name)
      raise ArgumentError, "template: #{app_name.inspect} is already a constant (#{name})"
    end

    name
  end

  # The template asserts the `rails new` flag set and stops before writing
  # anything when a flag is missing.
  def assert_flags!(argv)
    args = Array(argv).map(&:to_s)
    missing = REQUIRED_FLAGS.reject { |flag| args.include?(flag) }
    missing << "-d postgresql (or --database=postgresql)" unless postgresql?(args)

    return true if missing.empty?

    raise ArgumentError, "template: rails new is missing #{missing.join(', ')}"
  end

  def postgresql?(args)
    args.include?("--database=postgresql") ||
      (args.include?("--database") && args[args.index("--database") + 1] == "postgresql") ||
      args.each_cons(2).any? { |flag, value| flag == "-d" && value == "postgresql" }
  end

  # Copies every payload entry, renders the app namespace, and returns the
  # written paths. The payload source is `template/payload.yml`; the template
  # repository's own `.github/` and oss-kit callers are never listed there.
  def render!(source_root:, destination:, app_name:, version:)
    namespace = validate!(app_name)
    destination = File.expand_path(destination)
    FileUtils.mkdir_p(destination)

    written = []
    payload(source_root).each do |entry|
      source = File.expand_path(entry.fetch("source"), source_root)
      target_root = File.expand_path(entry.fetch("destination", entry.fetch("source")), destination)
      raise ArgumentError, "template: source is missing: #{source}" unless File.exist?(source)

      if File.file?(source)
        write_file(source, target_root, entry.fetch("mode", "copy"), app_name, namespace)
        written << target_root.delete_prefix("#{destination}/")
      else
        payload_files(source, entry).each do |file|
          relative = file.delete_prefix("#{source}/")
          target = File.join(target_root, relative)
          write_file(file, target, entry.fetch("mode", "copy"), app_name, namespace)
          written << target.delete_prefix("#{destination}/")
        end
      end
    end

    written.sort
  end

  def write_kernel_version!(destination:, version:)
    File.write(File.join(destination, "KERNEL_VERSION"), "#{version.to_s.strip}\n")
  end

  # Fails on a rendered app that still carries the placeholder app name. A
  # leftover would mean a payload file missed the namespace rendering.
  def leftover_paths(destination)
    root = File.expand_path(destination)
    Dir.glob(File.join(root, "**", "*"), File::FNM_DOTMATCH).filter_map do |path|
      next unless File.file?(path)
      next if path.split(File::SEPARATOR).include?(".git")

      relative = path.delete_prefix("#{root}/")
      text = File.binread(path).dup.force_encoding(Encoding::UTF_8)
      next unless text.valid_encoding?

      relative if relative.match?(/acme/i) || text.match?(/acme/i)
    end.sort
  end

  def verify_no_placeholders!(destination)
    leftovers = leftover_paths(destination)
    return if leftovers.empty?

    raise ArgumentError, "template: the rendered app still contains 'acme' in #{leftovers.join(', ')}"
  end

  def commit!(destination:, message: "Initial commit from the Rafelo template")
    Dir.chdir(File.expand_path(destination)) do
      system("git", "init", "-q") unless Dir.exist?(".git")
      system("git", "symbolic-ref", "HEAD", "refs/heads/main")
      system("git", "add", "-A", exception: true)
      system(
        "git",
        "-c", "user.name=#{TEMPLATE_AUTHOR_NAME}",
        "-c", "user.email=#{TEMPLATE_AUTHOR_EMAIL}",
        "-c", "commit.gpgsign=false",
        "commit", "-q", "-m", message,
        exception: true
      )
    end

    clean_tree = Dir.chdir(File.expand_path(destination)) { `git status --porcelain --untracked-files=all` }
    raise ArgumentError, "template: the initial commit left a dirty tree" unless clean_tree.strip.empty?

    true
  end

  def payload(source_root)
    path = File.join(source_root, "template", "payload.yml")
    raise ArgumentError, "template: payload manifest is missing: #{path}" unless File.file?(path)

    manifest = YAML.safe_load_file(path, aliases: false)
    entries = Array(manifest["paths"])
    raise ArgumentError, "template: payload manifest has no paths" if entries.empty?

    entries
  end

  def payload_files(source, entry)
    return [ source ] if File.file?(source)

    excludes = Array(entry["exclude"]).map(&:to_s)
    Dir.glob(File.join(source, "**", "*"), File::FNM_DOTMATCH).select do |file|
      next false unless File.file?(file)

      relative = file.delete_prefix("#{source}/")
      next false if excluded?(relative, excludes)

      true
    end.sort
  end

  def excluded?(relative, excludes)
    components = relative.split(File::SEPARATOR)
    return true if (components & DEFAULT_EXCLUDES).any?
    return true if DEFAULT_EXCLUDES.any? { |exclude| relative.start_with?("#{exclude}/") }

    excludes.any? { |pattern| File.fnmatch?(pattern, relative, File::FNM_PATHNAME | File::FNM_DOTMATCH) }
  end

  def write_file(source, target, mode, app_name, namespace)
    content = File.binread(source)
    text = content.dup.force_encoding(Encoding::UTF_8)
    output = if text.valid_encoding?
      render_text(text, mode.to_s, app_name, namespace)
    else
      content
    end

    FileUtils.mkdir_p(File.dirname(target))
    File.binwrite(target, output)
    FileUtils.chmod(File.stat(source).mode, target)
  end

  def render_text(text, mode, app_name, namespace)
    case mode
    when "app"
      replace_placeholders(text, app_name, namespace)
        .gsub(/\bRafelo\b(?!::(?:Core|DesignSystem|Generators))/, namespace)
        .yield_self { |rendered| replace_app_paths(rendered, app_name) }
    when "placeholder", "github"
      replace_placeholders(text, app_name, namespace)
    else
      text
    end
  end

  def replace_app_paths(text, app_name)
    slug = app_name.to_s.tr("-", "_")
    text
      .gsub(%r{(app/(?:controllers|policies|props|forms|gateways|models|jobs|public)/)rafelo/(?!core/|design_system/)}, "\\1#{slug}/")
      .gsub(%r{\blib/rafelo/(?!(?:core|design_system|page|module|domain|base|move_page|rename_module)/)}, "lib/#{slug}/")
  end

  def replace_placeholders(text, app_name, namespace)
    slug = app_name.to_s.tr("-", "_")
    text.gsub("Acme", namespace)
      .gsub("ACME", slug.upcase)
      .gsub("acme", slug)
  end
end
