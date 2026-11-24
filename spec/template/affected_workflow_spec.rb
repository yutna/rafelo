# frozen_string_literal: true

require "rails_helper"

RSpec.describe "affected selection in CI" do
  %w[.github/workflows/ci.yml template/.github/workflows/ci.yml].each do |path|
    describe path do
      let(:workflow) { File.read(Rails.root.join(path)) }

      it "consumes the design_system narrowing mode" do
        expect(workflow).to include("mode: ${{ steps.select.outputs.mode }}")
        expect(workflow).to include("if: needs.affected.outputs.mode != 'narrow'")
        expect(workflow.scan("if: needs.affected.outputs.mode != 'narrow'").length).to eq(2)
        expect(workflow).to include("script/ci/e2e --project design_system")
      end
    end
  end
end
