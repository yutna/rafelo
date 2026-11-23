# frozen_string_literal: true

require "fileutils"
require "open3"
require "tmpdir"
require "rails_helper"

RSpec.describe "script/ci/adoption" do
  let(:path) { File.expand_path("../../script/ci/adoption", __dir__) }
  let(:script) { File.read(path) }

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
    block = generated_page_block(script)
    expect(block).not_to match(/^\s*(?:if|while|until|for|case)\b/)
    expect(block).not_to match(/^\s*\[/)
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

  def git_repository
    Dir.mktmpdir("rafelo-adoption-") do |root|
      system("git", "-C", root, "init", "--quiet", exception: true)
      system("git", "-C", root, "config", "user.name", "Adoption", exception: true)
      system("git", "-C", root, "config", "user.email", "adoption@example.invalid", exception: true)
      yield root
    end
  end

  def write_and_commit(root, relative, content)
    full = File.join(root, relative)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, content)
    system("git", "-C", root, "add", relative, exception: true)
    system("git", "-C", root, "commit", "--quiet", "-m", "fixture", exception: true)
  end

  def run_guard(root, scope)
    env = { "ADOPTION_SCRIPT" => path, "ADOPTION_APP" => root, "ADOPTION_SCOPE" => scope }
    Open3.capture3(
      env, "bash", "-c",
      'source "$ADOPTION_SCRIPT"; check_no_placeholder "$ADOPTION_APP" "$ADOPTION_SCOPE"'
    )
  end

  it "finds a kernel example namespace anywhere in the app and skips app-owned docs" do
    git_repository do |root|
      write_and_commit(root, "docs/architecture/example.md", "Rafelo::Example\n")
      _out, err, status = run_guard(root, "examples")
      expect(status).to be_success, err
    end

    git_repository do |root|
      write_and_commit(root, "app/models/example.rb", "Rafelo::Example\n")
      _out, err, status = run_guard(root, "examples")
      expect(status).not_to be_success
      expect(err).to include("example engine kept the kernel namespace")
    end
  end

  it "reports a git search error as status 2, not as no match" do
    Dir.mktmpdir("rafelo-not-a-repo-") do |root|
      out, err, status = Open3.capture3(
        { "ADOPTION_SCRIPT" => path, "ADOPTION_APP" => root },
        "bash", "-c",
        'source "$ADOPTION_SCRIPT"; set +e; git_matches "$ADOPTION_APP" x .; echo "status=$?"'
      )
      expect(status).to be_success
      expect(out).to include("status=2")
      expect(err).to include("cannot search")
    end
  end

  def generated_page_block(text)
    start = text.index("# The N-1 generator's post-write steps")
    finish = text.index("# The generated slice's permission keys")
    expect(start).not_to be_nil
    expect(finish).to be > start
    text[start...finish]
  end

  def control_depth_at(text, needle)
    index = text.index(needle)
    expect(index).not_to be_nil
    depth = 0
    text[0...index].each_line do |line|
      stripped = line.strip
      next if stripped.start_with?("#")

      depth += stripped.scan(/\b(?:if|case|while|until|for)\b/).length
      depth -= stripped.scan(/\b(?:fi|esac|done)\b/).length
    end
    depth
  end
end
