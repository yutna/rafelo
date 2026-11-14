# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "tmpdir"
require "yaml"
require "rails_helper"

RSpec.describe "bin/kernel_update" do
  let(:script) { File.expand_path("../../script/ci/kernel_update", __dir__) }

  def write_release(root, version:, files:)
    FileUtils.mkdir_p(root)
    File.write(File.join(root, "VERSION"), "#{version}\n")
    manifest = {
      "paths" => [
        { "source" => "engines/core" },
        { "source" => "engines/design_system" },
        { "source" => "engines/example_orders" },
        { "source" => "script/ci" },
        { "source" => "script/contracts" },
        { "source" => "bin", "mode" => "app" },
        { "source" => "spec/fixtures" },
        { "source" => "config", "mode" => "app" },
        { "source" => ".opencode" }
      ]
    }
    FileUtils.mkdir_p(File.join(root, "template"))
    File.write(File.join(root, "template", "payload.yml"), YAML.dump(manifest))

    files.each do |relative, content|
      path = File.join(root, relative)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
      FileUtils.chmod(0o755, path) if relative.start_with?("bin/")
    end
  end

  def write_app(root, version:, files:)
    FileUtils.mkdir_p(File.join(root, "config"))
    File.write(File.join(root, "config", "application.rb"), <<~RUBY)
      # frozen_string_literal: true

      module SmokeShop
        class Application < Rails::Application
        end
      end
    RUBY
    File.write(File.join(root, "KERNEL_VERSION"), "#{version}\n")
    File.write(File.join(root, "VERSION"), "#{version}\n")

    files.each do |relative, content|
      path = File.join(root, relative)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
    end
  end

  def run_update(*arguments)
    Open3.capture3(RbConfig.ruby, script, *arguments)
  end

  let(:base_files) do
    {
      "engines/core/app/models/core_file.rb" => "base core\n",
      "script/ci/tool" => "#!/usr/bin/env ruby\nputs :base\n",
      "script/contracts/permissions" => "puts :base\n",
      "bin/check" => "#!/usr/bin/env ruby\nputs :base\n",
      "bin/kernel_update" => "#!/usr/bin/env ruby\nputs :base\n",
      "spec/fixtures/hostile_urls.json" => "[]\n",
      "config/budgets.yml" => "Acme::Budget\nmax: 1\n",
      "engines/design_system/forms/button.tsx" => "forms base\n",
      "engines/design_system/tables/table.tsx" => "tables base\n",
      "engines/example_orders/lib/example_orders/engine.rb" => "example base\n",
      ".opencode/skills/oo-test/SKILL.md" => "skill base\n"
    }
  end

  let(:target_files) do
    base_files.merge(
      "engines/core/app/models/core_file.rb" => "target core\n",
      "engines/core/app/models/new_file.rb" => "new core\n",
      "script/ci/tool" => "#!/usr/bin/env ruby\nputs :target\n",
      "script/contracts/permissions" => "puts :target\n",
      "bin/check" => "#!/usr/bin/env ruby\nputs :target\n",
      "bin/kernel_update" => "#!/usr/bin/env ruby\nputs :target\n",
      "spec/fixtures/hostile_urls.json" => "[\"target\"]\n",
      "config/budgets.yml" => "Acme::Budget\nmax: 2\n",
      "engines/design_system/forms/button.tsx" => "forms target\n",
      "engines/design_system/tables/table.tsx" => "tables target\n",
      "engines/example_orders/lib/example_orders/engine.rb" => "example target\n",
      ".opencode/skills/oo-test/SKILL.md" => "skill target\n"
    )
  end

  def local_files(base)
    base.transform_values { |content| content.gsub("Acme", "SmokeShop") }
  end

  it "updates the default kernel paths, renders the namespace and updates KERNEL_VERSION" do
    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(base_root, version: "0.1.0", files: base_files)
          write_release(target_root, version: "0.2.0", files: target_files)
          write_app(app_root, version: "0.1.0", files: local_files(base_files))

          _out, err, status = run_update("0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root)

          expect(status).to be_success, err
          expect(File.read(File.join(app_root, "engines/core/app/models/core_file.rb"))).to eq("target core\n")
          expect(File.read(File.join(app_root, "engines/core/app/models/new_file.rb"))).to eq("new core\n")
          expect(File.read(File.join(app_root, "script/ci/tool"))).to include(":target")
          expect(File.read(File.join(app_root, "script/contracts/permissions"))).to include(":target")
          expect(File.read(File.join(app_root, "bin/check"))).to include(":target")
          expect(File.read(File.join(app_root, "bin/kernel_update"))).to include(":target")
          expect(File.read(File.join(app_root, "spec/fixtures/hostile_urls.json"))).to include("target")
          expect(File.read(File.join(app_root, "config/budgets.yml"))).to eq("SmokeShop::Budget\nmax: 2\n")
          expect(File.read(File.join(app_root, "KERNEL_VERSION"))).to eq("0.2.0\n")

          expect(File.read(File.join(app_root, "engines/design_system/forms/button.tsx"))).to eq("forms base\n")
          expect(File.read(File.join(app_root, "engines/example_orders/lib/example_orders/engine.rb"))).to eq("example base\n")
          expect(File.read(File.join(app_root, ".opencode/skills/oo-test/SKILL.md"))).to eq("skill base\n")
        end
      end
    end
  end

  it "keeps a bootstrapped updater that already matches the target release" do
    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(base_root, version: "0.1.0", files: { "engines/core/app/models/core_file.rb" => "base\n" })
          write_release(
            target_root,
            version: "0.2.0",
            files: {
              "engines/core/app/models/core_file.rb" => "target\n",
              "bin/kernel_update" => "#!/usr/bin/env ruby\nputs :target\n"
            }
          )
          write_app(
            app_root,
            version: "0.1.0",
            files: {
              "engines/core/app/models/core_file.rb" => "base\n",
              "bin/kernel_update" => "#!/usr/bin/env ruby\nputs :target\n"
            }
          )

          _out, err, status = run_update("0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root)

          expect(status).to be_success, err
          expect(File.read(File.join(app_root, "bin/kernel_update"))).to include(":target")
          expect(File.read(File.join(app_root, "KERNEL_VERSION"))).to eq("0.2.0\n")
        end
      end
    end
  end

  it "leaves conflicts marked and updates KERNEL_VERSION only after --continue" do
    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(base_root, version: "0.1.0", files: { "config/budgets.yml" => "max: 1\n" })
          write_release(target_root, version: "0.2.0", files: { "config/budgets.yml" => "max: 3\n" })
          write_app(app_root, version: "0.1.0", files: { "config/budgets.yml" => "max: 2\n" })

          _out, _err, status = run_update("0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root)
          expect(status.exitstatus).to eq(1)
          expect(File.read(File.join(app_root, "config/budgets.yml"))).to include("<<<<<<<")
          expect(File.read(File.join(app_root, "KERNEL_VERSION"))).to eq("0.1.0\n")

          _out, _err, status = run_update("0.2.0", "--root", app_root, "--continue")
          expect(status.exitstatus).to eq(2)

          File.write(File.join(app_root, "config/budgets.yml"), "max: 2\n")
          _out, err, status = run_update("0.2.0", "--root", app_root, "--continue")
          expect(status).to be_success, err
          expect(File.read(File.join(app_root, "KERNEL_VERSION"))).to eq("0.2.0\n")
        end
      end
    end
  end

  it "updates a design_system folder only when --include names it" do
    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(base_root, version: "0.1.0", files: base_files)
          write_release(target_root, version: "0.2.0", files: target_files)
          write_app(app_root, version: "0.1.0", files: local_files(base_files))

          _out, err, status = run_update(
            "0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root,
            "--include", "design_system/forms"
          )

          expect(status).to be_success, err
          expect(File.read(File.join(app_root, "engines/design_system/forms/button.tsx"))).to eq("forms target\n")
          expect(File.read(File.join(app_root, "engines/design_system/tables/table.tsx"))).to eq("tables base\n")
        end
      end
    end
  end

  it "refuses a missing version, a missing release and a version mismatch" do
    Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
      write_app(app_root, version: "0.1.0", files: {})

      _out, err, status = run_update("--root", app_root)
      expect(status.exitstatus).to eq(2)
      expect(err).to include("VERSION is required")

      _out, err, status = run_update("0.2.0", "--root", app_root, "--base-source", "/does/not/exist", "--source", app_root)
      expect(status.exitstatus).to eq(2)
      expect(err).to include("release source is missing")

      _out, err, status = run_update("9.9.9", "--root", app_root, "--base-source", app_root, "--source", app_root)
      expect(status.exitstatus).to eq(2)
      expect(err).to include("expected v9.9.9")
    end
  end

  it "refuses an include outside design_system" do
    Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
      write_app(app_root, version: "0.1.0", files: {})

      _out, err, status = run_update("0.2.0", "--root", app_root, "--include", "../core")
      expect(status.exitstatus).to eq(2)
      expect(err).to include("--include must be design_system")
    end
  end
end
