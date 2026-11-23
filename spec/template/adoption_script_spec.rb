# frozen_string_literal: true

require "rails_helper"

RSpec.describe "script/ci/adoption" do
  let(:script) { File.read(File.expand_path("../../script/ci/adoption", __dir__)) }

  it "commits the N-1 update with an explicit identity" do
    expect(script).to include('user.name="Rafelo CI"')
    expect(script).to include('user.email="ci@rafelo.invalid"')
    expect(script).to include("-c commit.gpgsign=false")
  end

  it "fails on a missing base tag instead of skipping the N-1 proof" do
    expect(script).to include('rev-parse -q --verify "refs/tags/$base_tag"')
    expect(script.index("rev-parse -q --verify")).to be < script.index("predates the template payload")
  end

  it "generates a module and a page with the N-1 generator before the update" do
    module_call = script.index("rafelo:module legacy_check")
    page_call = script.index("rafelo:page legacy_check widgets --actions=index,new,edit")
    grants_call = script.index('File.join(root, "config/grants.json")')
    update_call = script.index('bin/kernel_update "$version"')
    setup_call = script.index("bin/setup --skip-server", script.index("adopting release"))

    expect(module_call).not_to be_nil
    expect(page_call).to be > module_call
    expect(setup_call).to be < module_call
    expect(grants_call).to be > page_call
    expect(update_call).to be > grants_call
    expect(script).to include("BUNDLE_FROZEN=false bundle check")
  end

  it "keeps the generated-page leg unconditional" do
    expect(script).not_to include('"0.36.0" "$base_version"')
    expect(script).not_to include("bin/rubocop -A")
    expect(control_depth_at(script, "rafelo:module legacy_check")).to eq(0)
    expect(control_depth_at(script, "rafelo:page legacy_check widgets")).to eq(0)
  end

  it "runs the documented rails new command and checks the template commit" do
    expect(script).to include("--skip-kamal")
    expect(script).to include("--skip-solid")
    expect(script).not_to include("--skip-bundle -m")
    expect(script).not_to include('BUNDLE_GEMFILE="$repo/Gemfile"')
    expect(script).to include("assert_template_commit_clean")
  end

  it "renders the refreshed examples with the app namespace" do
    expect(script).to include("RafeloTemplate.render_examples!")
    expect(script).not_to include('cp -R "$current_src/engines/$example"')
  end

  it "checks the app namespace across the whole N-1 app except app-owned docs" do
    expect(script).to include('gate "$work/smoke_shop_prev" examples')
    expect(script).to include('paths=(. ":(exclude)docs/architecture")')
    expect(script).to include('"${paths[@]}"')
    expect(script).to include("docs/architecture")
    expect(script).not_to include("paths=(spec/core engines/example_*")
  end

  it "fails closed when git cannot read or search the app" do
    expect(script).to include('"$status" -gt 1')
    expect(script).to include("cannot read the working tree")
    expect(script).to include("cannot list tracked files")
    expect(script).to include("cannot search")
  end

  def control_depth_at(text, needle)
    index = text.index(needle)
    expect(index).not_to be_nil
    depth = 0
    text[0...index].each_line do |line|
      stripped = line.strip
      next if stripped.start_with?("#")

      depth += stripped.scan(/\b(?:if|case)\b/).length
      depth -= stripped.scan(/\b(?:fi|esac)\b/).length
    end
    depth
  end
end
