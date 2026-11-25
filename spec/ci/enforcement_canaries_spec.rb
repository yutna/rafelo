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

  def prepare(root, destination)
    %w[app config engines script spec].each do |directory|
      FileUtils.cp_r(File.join(root, directory), destination)
    end
    %w[
      .dependency-cruiser.cjs .prettierignore .prettierrc.json .rubocop.yml
      eslint.config.mjs package.json tsconfig.base.json tsconfig.json tsconfig.tooling.json
    ].each do |file|
      FileUtils.cp(File.join(root, file), destination)
    end
    FileUtils.ln_s(File.join(root, "node_modules"), File.join(destination, "node_modules"))
  end

  it "passes on the real root and fails closed on broken meta inputs" do
    Dir.mktmpdir("rafelo-meta-canary-") do |directory|
      prepare(root, directory)
      output, status = run_meta(directory, script)
      expect(status.exitstatus).to eq(0), output

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
      expect(status.exitstatus).to eq(0), output
      expect(output).to include("fake-rule")
    end
  end
end
