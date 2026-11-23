# frozen_string_literal: true

require "rails_helper"

RSpec.describe "script/ci/generator_smoke" do
  let(:script) { File.read(File.expand_path("../../script/ci/generator_smoke", __dir__)) }

  it "removes its generated engines before the clean-tree check" do
    preflight = script.index("generated_engines=(smoke_party smoke_check smoke_other smoke_renamed)")
    check = script.index('git status --porcelain')

    expect(preflight).not_to be_nil
    expect(check).not_to be_nil
    expect(preflight).to be < check
    expect(script.index('rm -rf "engines/$engine"', preflight)).to be < check
  end

  it "removes them again in the cleanup before git clean" do
    cleanup = script.index("cleanup()")
    removal = script.index('rm -rf "engines/$engine"', cleanup)
    git_clean = script.index("git clean -fdq", cleanup)

    expect(cleanup).not_to be_nil
    expect(removal).to be > cleanup
    expect(removal).to be < git_clean
  end
end
