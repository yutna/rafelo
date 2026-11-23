# frozen_string_literal: true

require "fileutils"
require "open3"
require "tmpdir"
require "rails_helper"

RSpec.describe "script/ci/generator_smoke" do
  let(:script) { File.read(File.expand_path("../../script/ci/generator_smoke", __dir__)) }
  let(:path) { File.expand_path("../../script/ci/generator_smoke", __dir__) }

  it "checks the tree and committed engines before removing ignored residue" do
    check = script.index('git status --porcelain')
    tracked = script.index('git ls-files "engines/$engine"')
    trap = script.index("trap cleanup EXIT")
    clean = script.index("git clean -fdXq")

    expect(check).not_to be_nil
    expect(tracked).not_to be_nil
    expect(trap).not_to be_nil
    expect(clean).not_to be_nil
    expect(check).to be < tracked
    expect(tracked).to be < trap
    expect(trap).to be < clean
    expect(script[0...script.index("cleanup()")]).not_to include("rm -rf")
  end

  it "removes them again in the cleanup before git clean" do
    cleanup = script.index("cleanup()")
    removal = script.index('rm -rf "engines/$engine"', cleanup)
    git_clean = script.index("git clean -fdq", cleanup)

    expect(cleanup).not_to be_nil
    expect(removal).to be > cleanup
    expect(removal).to be < git_clean
  end

  def git_repository
    Dir.mktmpdir("rafelo-generator-smoke-") do |root|
      system("git", "-C", root, "init", "--quiet", exception: true)
      system("git", "-C", root, "config", "user.name", "Smoke", exception: true)
      system("git", "-C", root, "config", "user.email", "smoke@example.invalid", exception: true)
      yield root
    end
  end

  def run_smoke(root)
    Open3.capture3("bash", path, chdir: root)
  end

  it "refuses a dirty tree without deleting the work in a generated engine" do
    git_repository do |root|
      FileUtils.mkdir_p(File.join(root, "engines/smoke_check/node_modules"))
      File.write(File.join(root, "engines/smoke_check/work.txt"), "work\n")
      File.write(File.join(root, "engines/smoke_check/node_modules/cache"), "cache\n")
      File.write(File.join(root, ".gitignore"), "engines/*/node_modules/\n")
      system("git", "-C", root, "add", ".gitignore", exception: true)

      _out, err, status = run_smoke(root)

      expect(status).not_to be_success
      expect(err).to include("needs a clean working tree")
      expect(File.read(File.join(root, "engines/smoke_check/work.txt"))).to eq("work\n")
    end
  end

  it "refuses a committed engine instead of deleting it" do
    git_repository do |root|
      FileUtils.mkdir_p(File.join(root, "engines/smoke_check"))
      File.write(File.join(root, "engines/smoke_check/tracked.txt"), "tracked\n")
      system("git", "-C", root, "add", "engines/smoke_check/tracked.txt", exception: true)
      system("git", "-C", root, "commit", "--quiet", "-m", "tracked engine", exception: true)

      _out, err, status = run_smoke(root)

      expect(status).not_to be_success
      expect(err).to include("engines/smoke_check is tracked")
      expect(File.read(File.join(root, "engines/smoke_check/tracked.txt"))).to eq("tracked\n")
    end
  end
end
