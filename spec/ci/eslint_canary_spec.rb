# frozen_string_literal: true

require "fileutils"
require "open3"
require "rails_helper"
require "tmpdir"

# TS-07: a canary runs at real paths, so a renamed path must fail it instead of
# leaving a green canary against a stale virtual path.
RSpec.describe "eslint_canary paths" do
  root = File.expand_path("../..", __dir__)
  cases = File.join(root, "script", "ci", "eslint", "canary_cases")

  it "fails with checked 0 when a path does not exist" do
    Dir.mktmpdir("rafelo-eslint-paths-") do |directory|
      output, status = Open3.capture2e(
        RbConfig.ruby, "-r", cases, "-e",
        "Rafelo::ESLintCanary.existing_path(ARGV[0], 'engines/core/app/frontend/missing.ts')",
        directory
      )

      expect(status.exitstatus).to eq(1), output
      expect(output).to include("none of engines/core/app/frontend/missing.ts exists; checked 0")
    end
  end

  it "keeps the examples-removable fallback" do
    Dir.mktmpdir("rafelo-eslint-fallback-") do |directory|
      FileUtils.mkdir_p(File.join(directory, "app", "frontend", "pages", "home"))
      File.write(File.join(directory, "app", "frontend", "pages", "home", "index.tsx"), "")

      output, status = Open3.capture2e(
        RbConfig.ruby, "-r", cases, "-e",
        "puts Rafelo::ESLintCanary.existing_path(ARGV[0], " \
        "'engines/example_orders/app/frontend/pages/orders/index.tsx', " \
        "'app/frontend/pages/home/index.tsx')",
        directory
      )

      expect(status.exitstatus).to eq(0), output
      expect(output).to include("app/frontend/pages/home/index.tsx")
    end
  end
end
