# frozen_string_literal: true

require "rails_helper"

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
    end
  end
end
