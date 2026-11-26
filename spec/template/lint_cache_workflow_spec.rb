# frozen_string_literal: true

require "rails_helper"
require "yaml"

# 09_enforcement.md (lint performance): ESLint and Prettier keep their caches
# between CI runs, keyed by the files that change what they read. A miss only
# means the next run lints everything again.
RSpec.describe "Lint caches in CI" do
  WORKFLOW_PATHS = %w[.github/workflows/ci.yml template/.github/workflows/ci.yml].freeze
  CACHE_STEP = "Prepare ESLint and Prettier caches"

  def lint_steps(path)
    YAML.safe_load_file(Rails.root.join(path), aliases: true)
      .fetch("jobs").fetch("lint").fetch("steps")
  end

  WORKFLOW_PATHS.each do |path|
    describe path do
      it "caches the ESLint and Prettier cache directories" do
        step = lint_steps(path).find { |candidate| candidate["name"] == CACHE_STEP }

        expect(step).not_to be_nil
        expect(step.fetch("uses")).to match(%r{\Aactions/cache@[0-9a-f]{40}\z})
        expect(step.dig("with", "path")).to include("tmp/cache/eslint/root", "tmp/cache/prettier")
        expect(step.dig("with", "key")).to include("${{ env.LINT_HASH }}")
        expect(step.dig("with", "restore-keys")).to include("lint-${{ runner.os }}-${{ env.LINT_HASH }}-")
      end

      it "keys the cache on the lint configuration" do
        step = lint_steps(path).find { |candidate| candidate["name"] == CACHE_STEP }

        expect(step.dig("env", "LINT_HASH")).to include(
          "package-lock.json", "eslint.config.mjs", ".prettierrc.json", ".prettierignore"
        )
      end

      it "restores the cache before the lint steps" do
        names = lint_steps(path).map { |step| step["name"] }

        expect(names.index(CACHE_STEP)).to be < names.index("Lint - ESLint and Prettier")
        expect(names.index(CACHE_STEP)).to be < names.index("Lint - Prettier")
      end
    end
  end

  it "runs the scripts that write the cached locations" do
    scripts = JSON.parse(File.read(Rails.root.join("package.json"))).fetch("scripts")

    expect(scripts.fetch("lint")).to include("--cache", "--cache-location tmp/cache/eslint/root/")
    expect(scripts.fetch("format:check")).to include(
      "--cache", "--cache-location tmp/cache/prettier/"
    )
  end
end
