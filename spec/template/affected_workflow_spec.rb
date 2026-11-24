# frozen_string_literal: true

require "rails_helper"
require "yaml"

RSpec.describe "affected selection in CI" do
  %w[.github/workflows/ci.yml template/.github/workflows/ci.yml].each do |path|
    describe path do
      let(:workflow) { File.read(Rails.root.join(path)) }

      it "consumes the app and engine lanes" do
        expect(workflow).to include("app: ${{ steps.select.outputs.app }}")
        expect(workflow).to include("engines: ${{ steps.select.outputs.engines }}")
        expect(workflow).to include("script/ci/affected --format github")
        expect(workflow).to include("if: needs.affected.outputs.app == 'true'")
        expect(workflow).to include("if: needs.affected.outputs.engines != ''")
        expect(workflow).to include("AFFECTED_ENGINES: ${{ needs.affected.outputs.engines }}")
      end

      it "consumes the design_system narrowing and app e2e projects" do
        expect(workflow).to include("AFFECTED_MODE: ${{ needs.affected.outputs.mode }}")
        expect(workflow).to include("shell: bash")
        expect(workflow).to include("args=(--project design_system)")
        expect(workflow).to include('args=(--project app)')
        expect(workflow).to include('args+=(--project "$name")')
        expect(workflow).to include('script/ci/e2e "${args[@]}"')
      end

      it "runs the lockfile-only reduced lane and skips the full jobs" do
        expect(workflow).to include("if: needs.affected.outputs.mode == 'lockfile'")
        expect(workflow).to include("bin/bundler-audit")
        expect(workflow).to include("script/ci/npm_audit")
        expect(workflow).to include("script/ci/e2e --project app")
        expect(workflow).to include("if: needs.affected.outputs.mode != 'lockfile'")
      end

      it "leaves page matcher coverage to the full gate" do
        jobs = YAML.safe_load(workflow, aliases: true).fetch("jobs")
        test_steps = jobs.fetch("test").fetch("steps")
        expect(test_steps.map { |step| step["run"].to_s }).not_to include(
          a_string_including("pages:check -- --matchers")
        )
        expect(File.read(Rails.root.join("config/ci.rb"))).to include(
          "npm run pages:check -- --matchers"
        )
      end

      it "rebuilds the production image for either lockfile" do
        jobs = YAML.safe_load(workflow, aliases: true).fetch("jobs")
        decide = jobs.fetch("production-image-needed").fetch("steps").find { |step| step["id"] == "decide" }
        expect(decide.fetch("run")).to include("Gemfile\\.lock")
        expect(decide.fetch("run")).to include("package(-lock)?\\.json")
      end

      it "keeps the production image and adoption decisions outside the lockfile lane" do
        jobs = YAML.safe_load(workflow, aliases: true).fetch("jobs")
        expect(jobs.fetch("production-image-needed")).not_to have_key("if")
        expect(jobs.dig("production-image", "if")).to eq(
          "needs.production-image-needed.outputs.run == 'true'"
        )

        next unless jobs.key?("adoption-needed")

        expect(jobs.fetch("adoption-needed")).not_to have_key("if")
        expect(jobs.dig("adoption", "if")).to eq("needs.adoption-needed.outputs.current == 'true'")
        expect(jobs.dig("adoption-update", "if")).to eq("needs.adoption-needed.outputs.update == 'true'")
      end

      it "selects every lane on scheduled and manual runs" do
        expect(workflow).to include(
          'if [ "$GITHUB_EVENT_NAME" = "schedule" ] || [ "$GITHUB_EVENT_NAME" = "workflow_dispatch" ]; then'
        )
        expect(workflow).to include("script/ci/affected --all")
        expect(workflow).to include("script/ci/affected --all --format github >> \"$GITHUB_OUTPUT\"")
      end
    end
  end
end
