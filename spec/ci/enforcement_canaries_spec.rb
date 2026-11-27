# frozen_string_literal: true

require "fileutils"
require "open3"
require "rails_helper"
require "tmpdir"

RSpec.describe "enforcement_canaries" do
  root = File.expand_path("../..", __dir__)
  script = File.join(root, "script", "ci", "enforcement_canaries")

  def run_meta(root, script)
    Open3.capture2e(RbConfig.ruby, script, "--root", root)
  end

  # The meta-check reads the real guards and their fixtures; app, engines and
  # node_modules stay symlinked so ESLint resolves the same paths as in the
  # repository without copying the tree.
  def prepare(root, destination)
    %w[config script spec].each do |directory|
      FileUtils.cp_r(File.join(root, directory), destination)
    end
    %w[
      .dependency-cruiser.cjs .prettierignore .prettierrc.json .ruby-version .rubocop.yml
      eslint.config.mjs mise.toml package.json tsconfig.base.json tsconfig.json tsconfig.tooling.json
    ].each do |file|
      FileUtils.cp(File.join(root, file), destination)
    end
    %w[app engines].each do |directory|
      FileUtils.ln_s(File.join(root, directory), File.join(destination, directory))
    end
    FileUtils.ln_s(File.join(root, "node_modules"), File.join(destination, "node_modules"))
  end

  it "passes on the real root and fails closed on broken meta inputs" do
    output, status = run_meta(root, script)
    expect(status.exitstatus).to eq(0), output

    Dir.mktmpdir("rafelo-meta-canary-") do |directory|
      prepare(root, directory)

      node_modules = File.join(directory, "node_modules")
      FileUtils.rm_f(node_modules)
      FileUtils.mkdir_p(node_modules)
      output, status = run_meta(directory, script)
      expect(status.exitstatus).to eq(1), output
      expect(output).to include("eslint is not installed")

      fake_eslint = File.join(node_modules, ".bin", "eslint")
      FileUtils.mkdir_p(File.dirname(fake_eslint))
      File.write(fake_eslint, "#!/usr/bin/env ruby\nputs '{\"rules\":{}}'\n")
      FileUtils.chmod(0o755, fake_eslint)
      output, status = run_meta(directory, script)
      expect(status.exitstatus).to eq(1), output
      expect(output).to include("exports no rules")

      File.write(fake_eslint, "#!/usr/bin/env ruby\nwarn 'boom'\nexit 1\n")
      output, status = run_meta(directory, script)
      expect(status.exitstatus).to eq(1), output
      expect(output).to include("eslint --print-config failed")

      FileUtils.rm_rf(node_modules)
      FileUtils.ln_s(File.join(root, "node_modules"), node_modules)

      FileUtils.rm_f(File.join(directory, "config", "ci.rb"))
      output, status = run_meta(directory, script)
      expect(status.exitstatus).to eq(1), output
      expect(output).to include("config/ci.rb is missing")

      File.write(File.join(directory, "config", "ci.rb"),
                 "# step \"Example\", \"script/ci/affected\"\n# step \"Example\", \"script/ci/cops_canary\"\n")
      output, status = run_meta(directory, script)
      expect(status.exitstatus).to eq(1), output
      expect(output).to include("no script/ci steps")

      FileUtils.cp(File.join(root, "config", "ci.rb"), File.join(directory, "config", "ci.rb"))
      File.write(File.join(directory, "script", "ci", "cops", "rafelo", "fake_cop.rb"),
                 "module RuboCop\n  module Cop\n    module Rafelo\n      class FakeCop < Base; end\n    end\n  end\nend\n")
      cops_output, cops_status = Open3.capture2e(RbConfig.ruby,
                                                 File.join(directory, "script", "ci", "cops_canary"),
                                                 chdir: directory)
      expect(cops_status.exitstatus).to eq(1), cops_output
      expect(cops_output).to include("Rafelo/FakeCop")
      FileUtils.rm_f(File.join(directory, "script", "ci", "cops", "rafelo", "fake_cop.rb"))

      config = File.join(directory, ".dependency-cruiser.cjs")
      File.write(config, File.read(config).sub(
        "forbidden: [",
        "forbidden: [\n    {\n      name: \"fake-rule\",\n      severity: \"error\",\n      from: {},\n      to: {}\n    },"
      ))
      output, status = run_meta(directory, script)
      expect(status.exitstatus).to eq(1), output
      expect(output).to include("no canary for fake-rule")
      FileUtils.cp(File.join(root, ".dependency-cruiser.cjs"), config)

      ci_config = File.join(directory, "config", "ci.rb")
      File.write(ci_config, File.read(ci_config).sub(
        /^\s*step .*?"script\/ci\/apply_check_canary"\n/, ""
      ))
      output, status = run_meta(directory, script)
      expect(status.exitstatus).to eq(1), output
      expect(output).to include("canary script not wired into config/ci.rb: apply_check_canary")
      FileUtils.cp(File.join(root, "config", "ci.rb"), ci_config)

      eslint_config = File.join(directory, "eslint.config.mjs")
      File.write(eslint_config, File.read(eslint_config).sub(%(      "react/no-danger": "error",\n), ""))
      output, status = run_meta(directory, script)
      expect(status.exitstatus).to eq(1), output
      expect(output).to include("spec ESLint rule is not enabled: react/no-danger")
      FileUtils.cp(File.join(root, "eslint.config.mjs"), eslint_config)

      plugin = File.join(directory, "script", "ci", "eslint", "rafelo.mjs")
      File.write(plugin, File.read(plugin).sub(
        '"skip-needs-issue": skipNeedsIssue }',
        '"skip-needs-issue": skipNeedsIssue, "fake-rule": skipNeedsIssue }'
      ))
      File.write(eslint_config, File.read(eslint_config).sub(
        %("rafelo/skip-needs-issue": "error",),
        %("rafelo/skip-needs-issue": "error",\n      "rafelo/fake-rule": "error",)
      ))
      output, status = run_meta(directory, script)
      expect(status.exitstatus).to eq(1), output
      expect(output).to include("no canary for rafelo/fake-rule")
    end

    Dir.mktmpdir("rafelo-meta-empty-") do |directory|
      output, status = run_meta(directory, script)
      expect(status.exitstatus).to eq(1), output
      expect(output).to include("config/ci.rb is missing; checked 0")
    end
  end
end
