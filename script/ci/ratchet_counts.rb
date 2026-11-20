# frozen_string_literal: true

require "open3"
require "yaml"

# Computes the counts behind the ratchet files. `script/ci/ratchet --check`
# (the default mode) compares the real counts with the committed ceilings: a
# value above its committed ceiling fails even when the YAML file was not
# edited, and a recorded rise needs an owner's approval;
# `script/ci/ratchet --update` uses this module to lower a ceiling after code
# fell. Counts that need a tool (the cross-engine clone baseline) are
# computed by the existing clones script.
module RatchetCounts
  SKIP_FORMS = [
    /(?<![\w.:])skip(?![\w:])/,
    /\b(?:xit|xspecify|xexample|xdescribe|xcontext)\b/,
    /\.skip\b/,
    /\bpending(?!\s*:)\b/,
    /\b(?:skip|pending):/,
    /\bprosopite:\s*false\b/,
    /\bProsopite\.pause\b/,
    /\b(?:it|test|describe)\.(?:todo|skipIf|fixme)\b/,
    /\btest\.describe\.(?:skip|fixme)\b/
  ].freeze
  ISSUE_REFERENCE = /(?:#\d+|https:\/\/github\.com\/[^\/\s]+\/[^\/\s]+\/issues\/\d+)/

  module_function

  def for(root, file, clones: true)
    if file == "config/ratchets.yml"
      root_counts(root, clones: clones)
    else
      engine_counts(root, File.join(root, "engines", file.split("/")[1]))
    end
  end

  def root_counts(root, clones:)
    kernel = [ File.join(root, "engines", "core"), File.join(root, "engines", "design_system") ]
    dirs = [ root, *kernel ]
    app_ruby = %w[app lib config db spec].flat_map { |sub| glob(root, sub, "**", "*.rb") }
    counts(
      frontend: dirs.flat_map { |dir| glob(dir, "app", "frontend", "**", "*.{ts,tsx}") },
      ruby: app_ruby + kernel.flat_map { |dir| glob(dir, "**", "*.rb") },
      tests: dirs.flat_map { |dir| test_globs(dir) },
      clone_root: clones ? root : nil
    ).merge(
      "legacy_lint_paths" => legacy_lint_paths(root)
    )
  end

  def engine_counts(root, engine_dir)
    counts(
      frontend: glob(engine_dir, "app", "frontend", "**", "*.{ts,tsx}"),
      ruby: glob(engine_dir, "**", "*.rb"),
      tests: test_globs(engine_dir),
      clone_root: nil
    ).merge(
      "page_budget_overrides" => page_budget_overrides(engine_dir),
      "legacy_table_prefixes" => legacy_table_prefixes(engine_dir),
      "legacy_constants" => legacy_constants(engine_dir)
    )
  end

  def counts(frontend:, ruby:, tests:, clone_root:)
    frontend = clean(frontend).reject { |path| path.include?("/spec/") }
    ruby = clean(ruby)
    tests = clean(tests)
    result = {
      "eslint_disable" => frontend.sum { |path| File.read(path).scan(/eslint-disable/).length },
      "use_no_memo" => frontend.sum { |path| File.read(path).scan(/"use no memo"/).length },
      "rubocop_disable" => ruby.sum { |path| File.read(path).scan(/rubocop:disable/).length },
      "skipped_tests" => tests.sum { |path| skipped_tests(path) }
    }
    result["clone_baseline_entries"] = clone_baseline(clone_root) unless clone_root.nil?
    result
  end

  def glob(dir, *parts)
    Dir[File.join(dir, *parts)]
  end

  def test_globs(dir)
    [
      glob(dir, "spec", "**", "*"),
      glob(dir, "e2e", "**", "*.ts"),
      glob(dir, "app", "frontend", "**", "*.test.ts"),
      glob(dir, "app", "frontend", "**", "*.test.tsx")
    ].flatten
  end

  def clean(paths)
    paths.select { |path| File.file?(path) }
         .reject { |path| path.include?("/node_modules/") || path.include?("/spec/enforcement/fixtures/") }
         .uniq
         .sort
  end

  def skipped_tests(path)
    return 0 unless path.match?(/\.(?:rb|ts|tsx)\z/)

    File.readlines(path, chomp: true).count do |line|
      code = line.split(/\s+#\s*/, 2).first || ""
      next false if code.lstrip.start_with?("#")
      next false unless line.match?(ISSUE_REFERENCE)

      code = code.gsub(/(["']).*?\1/, '""')
      SKIP_FORMS.any? { |form| code.match?(form) }
    end
  end

  def clone_baseline(root)
    script = File.join(root, "script", "ci", "clones")
    return nil unless File.executable?(script)

    output, status = Open3.capture2e(script, "--root", root, chdir: root)
    abort "ratchet: clones failed: #{output}" unless status.success?

    flay = output[/flay cross_engine=(\d+)/, 1].to_i
    jscpd = output[/jscpd .*?cross_engine=(\d+)/, 1].to_i
    [ flay, jscpd ].max
  end

  def page_budget_overrides(engine_dir)
    path = File.join(engine_dir, "config", "budgets.yml")
    return 0 unless File.file?(path)

    data = YAML.safe_load_file(path) || {}
    pages = data["pages"]
    pages.is_a?(Hash) ? pages.length : 0
  end

  def legacy_table_prefixes(engine_dir)
    path = File.join(engine_dir, "package.yml")
    return 0 unless File.file?(path)

    data = YAML.safe_load_file(path) || {}
    data.fetch("metadata", {}).key?("legacy_table_prefix") ? 1 : 0
  end

  def legacy_constants(engine_dir)
    path = File.join(engine_dir, "config", "initializers", "legacy_constants.rb")
    return 0 unless File.file?(path)

    File.readlines(path, chomp: true).count do |line|
      line.match?(/^\s*[A-Z][A-Za-z0-9_]*\s*=/)
    end
  end

  # legacy_lint_paths: the number of distinct app/ paths recorded by a
  # "legacy-lint-path:" marker comment on a line of its own in the
  # configurations that exempt them: `# legacy-lint-path: app/models/billing`
  # in .rubocop.yml, `// legacy-lint-path: app/frontend/pages/billing` in
  # eslint.config.mjs (09_enforcement.md, Ratchets; owner wording, #601).
  # The marker checks fail the ratchet on a marker whose path is outside app/,
  # contains a glob, does not exist, appears on no other line of its file, or
  # is marked twice in one file; the two configurations are guard files, so
  # an exemption added without a marker still needs an owner through
  # guard_approval.
  LEGACY_LINT_FILES = %w[.rubocop.yml eslint.config.mjs].freeze
  LEGACY_LINT_MARKER = /\A\s*(?:#|\/\/)\s*legacy-lint-path:\s*(\S+)\s*\z/
  LEGACY_LINT_GLOB = /[*?\[\]{}]/

  def legacy_lint_paths(root)
    marked = []
    errors = []
    LEGACY_LINT_FILES.each do |file|
      path = File.join(root, file)
      next unless File.file?(path)

      lines = File.readlines(path, chomp: true)
      in_file = {}
      lines.each do |line|
        match = line.match(LEGACY_LINT_MARKER)
        next unless match

        named = match[1]
        if named.start_with?("app/") && File.exist?(File.join(root, named))
          unless lines.any? { |other| other != line && other.include?(named) }
            errors << "#{file}: legacy-lint-path for #{named} appears on no other line of #{file}"
          end
          if in_file.key?(named)
            errors << "#{file}: legacy-lint-path for #{named} is marked twice in #{file}"
          end
        elsif !named.start_with?("app/")
          errors << "#{file}: legacy-lint-path names a path outside app/: #{named}"
        elsif named.match?(LEGACY_LINT_GLOB)
          errors << "#{file}: legacy-lint-path names a glob: #{named}"
        else
          errors << "#{file}: legacy-lint-path names a path that does not exist: #{named}"
        end
        in_file[named] = true
        marked << named
      end
    end
    abort "ratchet: invalid legacy_lint_path markers: #{errors.join("; ")}" unless errors.empty?

    marked.uniq.length
  end
end
