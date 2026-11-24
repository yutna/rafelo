# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"
require "tmpdir"
require "yaml"
require "rails_helper"
load Rails.root.join("script/ci/kernel_update").to_s

RSpec.describe "bin/kernel_update" do
  it "carries the kernel test helpers and the lint tooling" do
    expect(KernelUpdate::DEFAULT_PATHS).to include(
      "spec/rails_helper.rb", "spec/spec_helper.rb", "eslint.config.mjs",
      ".prettierignore", ".prettierrc.json", "config/ratchets.yml", "docs/contracts.md",
      "script/contracts", "script/docs", "playwright.config.ts", "spec/core", "spec/upstream",
      "app/controllers/core", ".kamal/secrets.example", "docs/deployment.md",
      "docs/operations/audit.md", "docs/operations/backup-restore.md", "docs/operations/database-roles.md"
    )
  end

  it "refreshes the core controllers, the deploy secrets example, and the operations docs" do
    base = {
      "app/controllers/core/metrics_controller.rb" => "module Rafelo::Core\n  class MetricsController\n  end\nend\n",
      ".kamal/secrets.example" => "RAILS_MASTER_KEY=$(cat config/master.key)\n",
      "docs/deployment.md" => "First deploy: old order\n",
      "docs/operations/audit.md" => "Old audit runbook\n",
      "docs/operations/backup-restore.md" => "Old restore runbook\n",
      "docs/operations/database-roles.md" => "Old role runbook\n"
    }
    target = {
      "app/controllers/core/metrics_controller.rb" => "module Rafelo::Core\n  class MetricsController\n    def show = head(:ok)\n  end\nend\n",
      ".kamal/secrets.example" => "RAILS_MASTER_KEY=$RAILS_MASTER_KEY\n",
      "docs/deployment.md" => "First deploy: new order\n",
      "docs/operations/audit.md" => "New audit runbook\n",
      "docs/operations/backup-restore.md" => "New restore runbook\n",
      "docs/operations/database-roles.md" => "New role runbook\n"
    }

    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(base_root, version: "0.1.0", files: base)
          write_release(target_root, version: "0.2.0", files: target)
          write_app(app_root, version: "0.1.0", files: base)

          _out, err, status = run_update("0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root)

          expect(status).to be_success, err
          target.each do |relative, content|
            expect(File.read(File.join(app_root, relative))).to eq(content), relative
          end
        end
      end
    end
  end

  it "renders docs placeholders without touching the kernel names" do
    base = {
      "docs/operations/backup-restore.md" =>
        "# Ops\nUse Acme::Core and acme/core with ACME and acme.\nold command\n"
    }
    target = {
      "docs/operations/backup-restore.md" =>
        "# Ops\nUse Acme::Core and acme/core with ACME and acme.\nnew command\n"
    }
    local = {
      "docs/operations/backup-restore.md" =>
        "# Ops\nUse Rafelo::Core and rafelo/core with SMOKE_SHOP and smoke_shop.\nold command\n"
    }

    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(base_root, version: "0.1.0", files: base)
          write_release(target_root, version: "0.2.0", files: target)
          write_app(app_root, version: "0.1.0", files: local)

          _out, err, status = run_update("0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root)

          expect(status).to be_success, err
          expect(File.read(File.join(app_root, "docs/operations/backup-restore.md"))).to eq(
            "# Ops\nUse Rafelo::Core and rafelo/core with SMOKE_SHOP and smoke_shop.\nnew command\n"
          )
        end
      end
    end
  end

  it "keeps app-owned paths behind the --app-owned option" do
    expect(KernelUpdate::APP_OWNED_PATHS).to include(
      "app/frontend", "config/locales", "e2e", "engines/design_system/e2e", "AGENTS.md", "config/application.rb",
      "config/database.yml", "config/storage.yml", "config/frontend_react.mts", "lib/tasks",
      "package.json", "package-lock.json", ".devcontainer", "Dockerfile",
      "spec/config", "spec/requests", "spec/support", "spec/tasks"
    )
    expect(KernelUpdate::DEFAULT_PATHS).not_to include(*KernelUpdate::APP_OWNED_PATHS)
  end

  it "updates an unchanged app-owned locale source only with --app-owned" do
    base = { "config/locales/en.yml" => "en:\n  app:\n    title: Base\n" }
    target = { "config/locales/en.yml" => "en:\n  app:\n    title: Target\n" }

    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(base_root, version: "0.1.0", files: base)
          write_release(target_root, version: "0.2.0", files: target)
          write_app(app_root, version: "0.1.0", files: base)

          _out, err, status = run_update(
            "0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root
          )
          expect(status).to be_success, err
          expect(File.read(File.join(app_root, "config/locales/en.yml"))).to eq(base.fetch("config/locales/en.yml"))

          _out, err, status = run_update(
            "0.2.0", "--root", app_root, "--base-version", "0.1.0",
            "--base-source", base_root, "--source", target_root, "--app-owned"
          )
          expect(status).to be_success, err
          expect(File.read(File.join(app_root, "config/locales/en.yml"))).to eq(target.fetch("config/locales/en.yml"))
        end
      end
    end
  end

  it "leaves a customized app-owned file alone even when --app-owned is given" do
    base = { "config/locales/en.yml" => "en:\n  app:\n    title: Base\n    nav: Base\n" }
    target = { "config/locales/en.yml" => "en:\n  app:\n    title: Target\n    nav: Base\n" }
    local = { "config/locales/en.yml" => "en:\n  app:\n    title: Base\n    nav: Custom\n" }

    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(base_root, version: "0.1.0", files: base)
          write_release(target_root, version: "0.2.0", files: target)
          write_app(app_root, version: "0.1.0", files: local)

          _out, err, status = run_update(
            "0.2.0", "--root", app_root, "--base-version", "0.1.0",
            "--base-source", base_root, "--source", target_root, "--app-owned"
          )

          expect(status).to be_success, err
          expect(File.read(File.join(app_root, "config/locales/en.yml"))).to eq(local.fetch("config/locales/en.yml"))
        end
      end
    end
  end

  it "updates a kernel-owned spec change from the base release" do
    base = { "spec/core/audit_spec.rb" => "resource = \"rafelo/example_orders/orders\"\n" }
    target = { "spec/core/audit_spec.rb" => "resource = \"admin/orders\"\n" }

    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(base_root, version: "0.1.0", files: base)
          write_release(target_root, version: "0.2.0", files: target)
          write_app(app_root, version: "0.1.0", files: base)

          _out, err, status = run_update(
            "0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root
          )

          expect(status).to be_success, err
          expect(File.read(File.join(app_root, "spec/core/audit_spec.rb"))).to eq(target.fetch("spec/core/audit_spec.rb"))
        end
      end
    end
  end

  let(:script) { File.expand_path("../../script/ci/kernel_update", __dir__) }

  def write_release(root, version:, files:)
    FileUtils.mkdir_p(root)
    File.write(File.join(root, "VERSION"), "#{version}\n")
    manifest = {
      "paths" => [
        { "source" => "app", "mode" => "app" },
        { "source" => ".kamal" },
        { "source" => "docs", "mode" => "docs" },
        { "source" => "engines/core" },
        { "source" => "engines/design_system" },
        { "source" => "engines/example_orders" },
        { "source" => "script/ci" },
        { "source" => "script/contracts" },
        { "source" => "bin", "mode" => "app" },
        { "source" => "spec", "mode" => "app" },
        { "source" => "lib", "mode" => "app" },
        { "source" => "config", "mode" => "app" },
        { "source" => "package.json", "mode" => "app" },
        { "source" => "package-lock.json", "mode" => "app" },
        { "source" => ".devcontainer", "mode" => "app" },
        { "source" => "Dockerfile", "mode" => "app" },
        { "source" => ".opencode" },
        { "source" => "template/.github", "destination" => ".github", "mode" => "github" }
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
      "spec/upstream/drift_spec.rb" => "base drift\n",
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
      "spec/upstream/drift_spec.rb" => "target drift\n",
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
          expect(File.read(File.join(app_root, "spec/upstream/drift_spec.rb"))).to eq("target drift\n")
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

  it "compares non-ASCII kernel files by bytes" do
    base = { "script/ci/tool" => "#!/usr/bin/env ruby\nputs \"base — dash\"\n" }
    target = { "script/ci/tool" => "#!/usr/bin/env ruby\nputs \"target — dash\"\n" }

    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(base_root, version: "0.1.0", files: base)
          write_release(target_root, version: "0.2.0", files: target)
          write_app(app_root, version: "0.1.0", files: target)

          _out, err, status = run_update("0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root)

          expect(status).to be_success, err
          expect(File.read(File.join(app_root, "script/ci/tool"))).to eq(target.fetch("script/ci/tool"))
        end
      end
    end
  end

  it "writes conflict markers for a genuinely customized non-ASCII kernel file" do
    base = { "script/ci/tool" => "#!/usr/bin/env ruby\nputs \"base — dash\"\n" }
    target = { "script/ci/tool" => "#!/usr/bin/env ruby\nputs \"target — dash\"\n" }
    local = { "script/ci/tool" => "#!/usr/bin/env ruby\nputs \"custom — dash\"\n" }

    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(base_root, version: "0.1.0", files: base)
          write_release(target_root, version: "0.2.0", files: target)
          write_app(app_root, version: "0.1.0", files: local)

          _out, err, status = run_update("0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root)

          expect(status.exitstatus).to eq(1)
          expect(err).not_to include("Encoding::CompatibilityError")
          expect(File.read(File.join(app_root, "script/ci/tool"))).to include(
            "<<<<<<<", "custom — dash", "=======", "target — dash", ">>>>>>>"
          )
        end
      end
    end
  end

  it "updates the app-owned specs, tasks, packaging and container names that follow the app name" do
    base = {
      "config/database.yml" => "role: rafelo_runtime\n",
      "config/storage.yml" => "bucket: rafelo-production\n",
      "spec/config/database_roles_spec.rb" => "ENV[\"RAFELO_DATABASE_ROLE\"]\n",
      "spec/requests/write_flow_spec.rb" => "cookie: rafelo_session\n",
      "spec/support/authentication.rb" => "rafelo_session\n",
      "spec/tasks/restore_spec.rb" => "ENV[\"RAFELO_DATABASE_ROLE\"]\n",
      "lib/tasks/restore.rake" => "ENV[\"RAFELO_DATABASE_ROLE\"]\n",
      "package.json" => "{\"name\":\"rafelo\"}\n",
      "package-lock.json" => "{\"name\":\"rafelo\"}\n",
      ".devcontainer/compose.yaml" => "image: rafelo-devcontainer\n",
      "Dockerfile" => "ARG RAFELO_NAME\n"
    }
    target = base.transform_values do |content|
      content.gsub("RAFELO", "ACME").gsub("rafelo", "acme")
    end

    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(base_root, version: "0.1.0", files: base)
          write_release(target_root, version: "0.2.0", files: target)
          write_app(app_root, version: "0.1.0", files: base)

          _out, err, status = run_update("0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root)

          expect(status).to be_success, err
          expect(File.read(File.join(app_root, "config/database.yml"))).to eq("role: rafelo_runtime\n")
          expect(File.read(File.join(app_root, "spec/config/database_roles_spec.rb"))).to eq("ENV[\"RAFELO_DATABASE_ROLE\"]\n")
          expect(File.read(File.join(app_root, "spec/requests/write_flow_spec.rb"))).to eq("cookie: rafelo_session\n")
          expect(File.read(File.join(app_root, "spec/support/authentication.rb"))).to eq("rafelo_session\n")
          expect(File.read(File.join(app_root, "spec/tasks/restore_spec.rb"))).to eq("ENV[\"RAFELO_DATABASE_ROLE\"]\n")
          expect(File.read(File.join(app_root, "lib/tasks/restore.rake"))).to eq("ENV[\"RAFELO_DATABASE_ROLE\"]\n")
          expect(File.read(File.join(app_root, "config/storage.yml"))).to eq("bucket: rafelo-production\n")
          expect(File.read(File.join(app_root, "package.json"))).to eq("{\"name\":\"rafelo\"}\n")
          expect(File.read(File.join(app_root, "package-lock.json"))).to eq("{\"name\":\"rafelo\"}\n")
          expect(File.read(File.join(app_root, ".devcontainer/compose.yaml"))).to eq("image: rafelo-devcontainer\n")
          expect(File.read(File.join(app_root, "Dockerfile"))).to eq("ARG RAFELO_NAME\n")

          _out, err, status = run_update(
            "0.2.0", "--root", app_root, "--base-version", "0.1.0",
            "--base-source", base_root, "--source", target_root, "--app-owned"
          )

          expect(status).to be_success, err
          expect(File.read(File.join(app_root, "config/database.yml"))).to eq("role: smoke_shop_runtime\n")
          expect(File.read(File.join(app_root, "spec/config/database_roles_spec.rb"))).to eq("ENV[\"SMOKE_SHOP_DATABASE_ROLE\"]\n")
          expect(File.read(File.join(app_root, "spec/requests/write_flow_spec.rb"))).to eq("cookie: smoke_shop_session\n")
          expect(File.read(File.join(app_root, "spec/support/authentication.rb"))).to eq("smoke_shop_session\n")
          expect(File.read(File.join(app_root, "spec/tasks/restore_spec.rb"))).to eq("ENV[\"SMOKE_SHOP_DATABASE_ROLE\"]\n")
          expect(File.read(File.join(app_root, "lib/tasks/restore.rake"))).to eq("ENV[\"SMOKE_SHOP_DATABASE_ROLE\"]\n")
          expect(File.read(File.join(app_root, "config/storage.yml"))).to eq("bucket: smoke_shop-production\n")
          expect(File.read(File.join(app_root, "package.json"))).to eq("{\"name\":\"smoke_shop\"}\n")
          expect(File.read(File.join(app_root, "package-lock.json"))).to eq("{\"name\":\"smoke_shop\"}\n")
          expect(File.read(File.join(app_root, ".devcontainer/compose.yaml"))).to eq("image: smoke_shop-devcontainer\n")
          expect(File.read(File.join(app_root, "Dockerfile"))).to eq("ARG SMOKE_SHOP_NAME\n")
        end
      end
    end
  end


  it "never updates an engine guide the app owns" do
    base = {
      "engines/core/AGENTS.md" => "base guide\n",
      "engines/core/app/models/core_file.rb" => "base core\n"
    }
    target = base.merge(
      "engines/core/AGENTS.md" => "target guide\n",
      "engines/core/app/models/core_file.rb" => "target core\n"
    )
    local = base.merge("engines/core/AGENTS.md" => "local guide\n")

    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(base_root, version: "0.1.0", files: base)
          write_release(target_root, version: "0.2.0", files: target)
          write_app(app_root, version: "0.1.0", files: local)

          _out, err, status = run_update("0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root)

          expect(status).to be_success, err
          expect(File.read(File.join(app_root, "engines/core/AGENTS.md"))).to eq("local guide\n")
          expect(File.read(File.join(app_root, "engines/core/app/models/core_file.rb"))).to eq("target core\n")
        end
      end
    end
  end

  it "does not add files the release payload does not ship" do
    base = { "engines/core/app/models/core_file.rb" => "base core\n" }
    target = base.merge(
      "engines/core/app/models/new_file.rb" => "new core\n",
      "spec/generators/unshipped_spec.rb" => "unshipped\n"
    )

    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(base_root, version: "0.1.0", files: base)
          write_release(target_root, version: "0.2.0", files: target)
          File.write(
            File.join(target_root, "template", "payload.yml"),
            YAML.dump("paths" => [ { "source" => "engines/core" } ])
          )
          write_app(app_root, version: "0.1.0", files: base)

          _out, err, status = run_update("0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root)

          expect(status).to be_success, err
          expect(File.read(File.join(app_root, "engines/core/app/models/new_file.rb"))).to eq("new core\n")
          expect(File.exist?(File.join(app_root, "spec/generators/unshipped_spec.rb"))).to be(false)
        end
      end
    end
  end

  it "refuses a release whose payload exists but ships no paths" do
    files = { "engines/core/app/models/core_file.rb" => "base core\n" }

    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(base_root, version: "0.1.0", files: files)
          write_release(target_root, version: "0.2.0", files: files)
          File.write(File.join(target_root, "template", "payload.yml"), YAML.dump("paths" => []))
          write_app(app_root, version: "0.1.0", files: files)

          _out, err, status = run_update(
            "0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root
          )

          expect(status).not_to be_success
          expect(err).to include("release payload has no paths")
        end
      end
    end
  end

  it "migrates only the exact generated new/edit props and controller shapes" do
    generated_new_props = <<~'RUBY'
      # frozen_string_literal: true

      module SmokeShop::Legacy
        class WidgetsNewProps < Rafelo::Core::PageProps
          def envelope
            {
              data: {
                createHref: context.urls.route(:legacy, :widgets),
                indexHref: context.urls.route(:legacy, :widgets)
              },
              meta: { formToken: Rafelo::Core::FormToken.issue(session_id: Rafelo::Core::Current.session&.id) },
              query: {},
              pagination: nil,
              can: {}
            }
          end
        end
      end
    RUBY
    generated_edit_props = <<~'RUBY'
      # frozen_string_literal: true

      module SmokeShop::Legacy
        class WidgetsEditProps < Rafelo::Core::PageProps
          def initialize(context:, id:)
            super(context: context)
            @id = id
          end

          def envelope
            {
              data: {
                widget: { id: @id, name: @id },
                updateHref: context.urls.route(:legacy, :widget, id: @id),
                showHref: context.urls.route(:legacy, :widget, id: @id)
              },
              meta: { formToken: Rafelo::Core::FormToken.issue(session_id: Rafelo::Core::Current.session&.id) },
              query: {},
              pagination: nil,
              can: {}
            }
          end
        end
      end
    RUBY
    generated_controller = <<~'RUBY'
      # frozen_string_literal: true

      module SmokeShop::Legacy
        class WidgetsController < Rafelo::Core::BaseController
          layout "application"

      def create
        authorize :widget, :create?, policy_class: SmokeShop::Legacy::WidgetPolicy
        form = SmokeShop::Legacy::WidgetForm.new(params.permit(:name, :token))
        back = page_context.urls.route(:legacy, :new_widget)
        if form.invalid?
          return redirect_after_write(back, errors: form.error_messages)
        end

        Rafelo::Core::IdempotencyClaim.call(
          self,
          token: form.token,
          payload: form.payload,
          back: back
        ) do |idempotency_key|
          created = gateway(SmokeShop::Legacy::WidgetsGateway).create(
            payload: form.payload, idempotency_key: idempotency_key
          )
          request.env["rafelo.audit.upstream_id"] = created.id.to_s if created.respond_to?(:id)
          redirect_after_write(page_context.urls.route(:legacy, :widgets), notice: "Created.")
        end
      rescue Rafelo::Core::ValidationFailed => error
        redirect_after_write(back, errors: form.translate(error.field_codes))
      rescue Rafelo::Core::ApplicationError => error
        raise unless error.code == "resource.conflict"

        redirect_after_write(back, errors: { "base" => I18n.t("core.errors.fields.conflict") })
      end
        end
      end
    RUBY
    irregular_edit_props = generated_edit_props
      .gsub("SmokeShop::Legacy", "SmokeShop::API")
      .gsub("Widgets", "Statuses")
      .gsub("widget:", "status:")
      .gsub(":widgets", ":statuses")
      .gsub(":widget", ":status")
      .gsub(":legacy", ":api")
    irregular_controller = generated_controller
      .gsub("SmokeShop::Legacy", "SmokeShop::API")
      .gsub("Widgets", "Statuses")
      .gsub("WidgetForm", "StatusForm")
      .gsub("WidgetPolicy", "StatusPolicy")
      .gsub("widgets", "statuses")
      .gsub("widget", "status")
      .gsub(":legacy", ":api")
    custom_new_props = generated_new_props
      .gsub("SmokeShop::Legacy", "SmokeShop::Custom")
      .gsub("WidgetsNewProps", "ThingsNewProps")
      .gsub(":legacy, :widgets", ":custom, :things")
      .sub("createHref: context.urls.route(:custom, :things)", "createHref: context.urls.route(:custom, :other)")
    custom_edit_props = generated_edit_props
      .gsub("SmokeShop::Legacy", "SmokeShop::Custom")
      .gsub("WidgetsEditProps", "ThingsEditProps")
      .gsub("widget:", "thing:")
      .gsub(":legacy, :widget", ":custom, :thing")
      .gsub("thing:", "gadget:")
    custom_controller = generated_controller
      .gsub("SmokeShop::Legacy", "SmokeShop::Custom")
      .gsub("Widgets", "Things")
      .gsub("WidgetForm", "ThingForm")
      .gsub("WidgetPolicy", "ThingPolicy")
      .gsub("widgets", "things")
      .gsub("widget", "thing")
      .gsub(":legacy", ":custom")
      .sub("def create\n", "def create\n  head :ok\n")
    evil_props = generated_new_props
      .gsub("SmokeShop::Legacy", "Evil::Legacy")
      .gsub("WidgetsNewProps", "GadgetsNewProps")
      .gsub(":legacy, :widgets", ":legacy, :gadgets")
    sku_props = generated_new_props
      .gsub("SmokeShop::Legacy", "SmokeShop::SKU")
      .gsub(":legacy, :widgets", ":sku, :widgets")
    abc_props = generated_new_props
      .gsub("SmokeShop::Legacy", "SmokeShop::ABC")
      .gsub(":legacy, :widgets", ":abc, :widgets")
    wrong_props = generated_new_props
      .gsub("SmokeShop::Legacy", "SmokeShop::Wrong")
      .gsub(":legacy, :widgets", ":wrong, :widgets")
    base = {
      "config/application.rb" =>
        "# frozen_string_literal: true\n\nmodule SmokeShop\n  class Application < Rails::Application\n  end\n\n  ActiveSupport::Inflector.inflections(:en) do |inflect|\n    inflect.acronym \"API\"\n  end\nend\n",
      "config/initializers/company_inflections.rb" =>
        "# frozen_string_literal: true\n# inflect.acronym \"WRONG\"\n\nActiveSupport::Inflector.inflections(:en) do |inflect|\n  inflect.acronym \"SKU\"\nend\n",
      "config/initializers/broken_inflections.rb" =>
        "raise \"this initializer needs a booted app\"\n",
      "engines/legacy/config/initializers/inflections.rb" =>
        "# frozen_string_literal: true\n\nActiveSupport::Inflector.inflections(:en) do |inflect|\n  inflect.acronym \"ABC\"\nend\n",
      "engines/legacy/app/props/smoke_shop/legacy/widgets_new_props.rb" => generated_new_props,
      "engines/legacy/app/props/smoke_shop/legacy/widgets_edit_props.rb" => generated_edit_props,
      "engines/legacy/app/props/smoke_shop/api/statuses_edit_props.rb" => irregular_edit_props,
      "engines/legacy/app/props/smoke_shop/legacy/gadgets_new_props.rb" => evil_props,
      "engines/legacy/app/props/smoke_shop/sku/widgets_new_props.rb" => sku_props,
      "engines/legacy/app/props/smoke_shop/abc/widgets_new_props.rb" => abc_props,
      "engines/legacy/app/props/smoke_shop/wrong/widgets_new_props.rb" => wrong_props,
      "engines/legacy/app/controllers/smoke_shop/legacy/widgets_controller.rb" => generated_controller,
      "engines/legacy/app/controllers/smoke_shop/api/statuses_controller.rb" => irregular_controller,
      "engines/custom/app/props/smoke_shop/custom/things_new_props.rb" => custom_new_props,
      "engines/custom/app/props/smoke_shop/custom/things_edit_props.rb" => custom_edit_props,
      "engines/custom/app/controllers/smoke_shop/custom/things_controller.rb" => custom_controller
    }
    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(base_root, version: "0.1.0", files: base)
          write_release(target_root, version: "0.2.0", files: base)
          write_app(app_root, version: "0.1.0", files: base)

          _out, err, status = run_update("0.2.0", "--root", app_root, "--base-source", base_root,
                                         "--source", target_root, "--migrate-generated")

          expect(status).to be_success, err
          props = File.read(File.join(app_root, "engines/legacy/app/props/smoke_shop/legacy/widgets_new_props.rb"))
          expect(props).to include("context.session_id")
          edit_props = File.read(File.join(app_root, "engines/legacy/app/props/smoke_shop/legacy/widgets_edit_props.rb"))
          expect(edit_props).to include("context.session_id")
          irregular = File.read(File.join(app_root, "engines/legacy/app/props/smoke_shop/api/statuses_edit_props.rb"))
          expect(irregular).to include("context.session_id")
          irregular_controller_file = File.read(File.join(app_root, "engines/legacy/app/controllers/smoke_shop/api/statuses_controller.rb"))
          expect(irregular_controller_file).to include('name: "legacy/write"')
          controller = File.read(File.join(app_root, "engines/legacy/app/controllers/smoke_shop/legacy/widgets_controller.rb"))
          expect(controller).to include('throttle to: 30, within: 1.minute, only: %i[create], name: "legacy/write"')
          custom_props = File.read(File.join(app_root, "engines/custom/app/props/smoke_shop/custom/things_new_props.rb"))
          expect(custom_props).to eq(custom_new_props)
          custom_edit = File.read(File.join(app_root, "engines/custom/app/props/smoke_shop/custom/things_edit_props.rb"))
          expect(custom_edit).to eq(custom_edit_props)
          custom_controller_file = File.read(File.join(app_root, "engines/custom/app/controllers/smoke_shop/custom/things_controller.rb"))
          expect(custom_controller_file).to eq(custom_controller)
          evil = File.read(File.join(app_root, "engines/legacy/app/props/smoke_shop/legacy/gadgets_new_props.rb"))
          expect(evil).to eq(evil_props)
          sku = File.read(File.join(app_root, "engines/legacy/app/props/smoke_shop/sku/widgets_new_props.rb"))
          expect(sku).to include("context.session_id")
          abc = File.read(File.join(app_root, "engines/legacy/app/props/smoke_shop/abc/widgets_new_props.rb"))
          expect(abc).to include("context.session_id")
          wrong = File.read(File.join(app_root, "engines/legacy/app/props/smoke_shop/wrong/widgets_new_props.rb"))
          expect(wrong).to include("context.session_id")
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


  it "updates the adopter .github from the payload directory" do
    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(
            base_root,
            version: "0.1.0",
            files: {
              "template/.github/workflows/ci.yml" => "name: base\n",
              "config/budgets.yml" => "max: 1\n"
            }
          )
          write_release(
            target_root,
            version: "0.2.0",
            files: {
              "template/.github/workflows/ci.yml" => "name: target\n",
              "config/budgets.yml" => "max: 1\n"
            }
          )
          write_app(
            app_root,
            version: "0.1.0",
            files: {
              ".github/workflows/ci.yml" => "name: base\n",
              "config/budgets.yml" => "max: 1\n"
            }
          )

          _out, err, status = run_update("0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root)

          expect(status).to be_success, err
          expect(File.read(File.join(app_root, ".github/workflows/ci.yml"))).to eq("name: target\n")
        end
      end
    end
  end

  it "marks an add/add conflict and refuses --continue until it is resolved" do
    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(base_root, version: "0.1.0", files: { "config/budgets.yml" => "max: 1\n" })
          write_release(
            target_root,
            version: "0.2.0",
            files: { "config/budgets.yml" => "max: 1\n", "config/errors.yml" => "{}\n" }
          )
          write_app(
            app_root,
            version: "0.1.0",
            files: { "config/budgets.yml" => "max: 1\n", "config/errors.yml" => "local: true\n" }
          )

          _out, _err, status = run_update("0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root)
          expect(status.exitstatus).to eq(1)
          expect(File.read(File.join(app_root, "config/errors.yml"))).to include("<<<<<<<")

          _out, _err, status = run_update("0.2.0", "--root", app_root, "--continue")
          expect(status.exitstatus).to eq(2)

          File.write(File.join(app_root, "config/errors.yml"), "{}\n")
          _out, err, status = run_update("0.2.0", "--root", app_root, "--continue")
          expect(status).to be_success, err
          expect(File.read(File.join(app_root, "KERNEL_VERSION"))).to eq("0.2.0\n")
        end
      end
    end
  end

  it "treats a multi-hunk conflict as a conflict, not an updater failure" do
    base = { "config/errors.yml" => "one: 1\nkeep1: 1\nkeep2: 1\nkeep3: 1\ntwo: 2\n" }
    target = { "config/errors.yml" => "one: 5\nkeep1: 1\nkeep2: 1\nkeep3: 1\ntwo: 6\n" }
    local = { "config/errors.yml" => "one: 3\nkeep1: 1\nkeep2: 1\nkeep3: 1\ntwo: 4\n" }

    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(base_root, version: "0.1.0", files: base)
          write_release(target_root, version: "0.2.0", files: target)
          write_app(app_root, version: "0.1.0", files: local)

          _out, err, status = run_update("0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root)

          expect(status.exitstatus).to eq(1), err
          expect(err).not_to include("git merge-file failed")
          expect(File.read(File.join(app_root, "config/errors.yml")))
            .to include("<<<<<<<", "one: 3", "one: 5", "two: 4", "two: 6")
        end
      end
    end
  end

  it "marks a delete/modify conflict and refuses --continue until the person decides" do
    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(base_root, version: "0.1.0", files: { "config/errors.yml" => "{}\n" })
          write_release(target_root, version: "0.2.0", files: {})
          write_app(app_root, version: "0.1.0", files: { "config/errors.yml" => "local: true\n" })

          _out, _err, status = run_update("0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root)
          expect(status.exitstatus).to eq(1)
          expect(File.read(File.join(app_root, "config/errors.yml"))).to include("<<<<<<<")

          _out, _err, status = run_update("0.2.0", "--root", app_root, "--continue")
          expect(status.exitstatus).to eq(2)

          FileUtils.rm_f(File.join(app_root, "config/errors.yml"))
          _out, err, status = run_update("0.2.0", "--root", app_root, "--continue")
          expect(status).to be_success, err
        end
      end
    end
  end


  it "writes a sidecar for binary add/add and delete/modify conflicts" do
    cases = [
      [ { "config/errors.yml" => "max: 1\n" },
        { "config/errors.yml" => "max: 1\n", "config/budgets.yml" => "PNG\x00target" },
        { "config/errors.yml" => "max: 1\n", "config/budgets.yml" => "PNG\x00local" } ],
      [ { "config/budgets.yml" => "PNG\x00base" },
        {},
        { "config/budgets.yml" => "PNG\x00local" } ]
    ]

    cases.each do |base, target, local|
      Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
        Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
          Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
            write_release(base_root, version: "0.1.0", files: base)
            write_release(target_root, version: "0.2.0", files: target)
            write_app(app_root, version: "0.1.0", files: local)

            _out, err, status = run_update("0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root)

            expect(status.exitstatus).to eq(1)
            expect(err).to include("--continue")
            expect(err).not_to include("--include")
            expect(File.exist?(File.join(app_root, "config/budgets.yml.conflict"))).to be(true), base.inspect
            expect(File.read(File.join(app_root, "config/budgets.yml"))).not_to include("<<<<<<<") if local.key?("config/budgets.yml")
          end
        end
      end
    end
  end

  it "finds an included design_system conflict on --continue without repeating --include" do
    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(base_root, version: "0.1.0", files: { "engines/design_system/forms/button.tsx" => "base\n" })
          write_release(target_root, version: "0.2.0", files: { "engines/design_system/forms/button.tsx" => "target\n" })
          write_app(app_root, version: "0.1.0", files: { "engines/design_system/forms/button.tsx" => "local\n" })

          _out, _err, status = run_update(
            "0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root,
            "--include", "design_system/forms"
          )
          expect(status.exitstatus).to eq(1)

          _out, _err, status = run_update("0.2.0", "--root", app_root, "--continue")
          expect(status.exitstatus).to eq(2)
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

  it "still blocks --continue when a person leaves a partial conflict marker" do
    [
      "<<<<<<< local\nmax: 2\n",
      "max: 2\n>>>>>>> target\n",
      "<<<<<<< local\nmax: 2\n=======\n",
      "max: 2\n=======\n>>>>>>> target\n"
    ].each do |partial|
      Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
        Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
          Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
            write_release(base_root, version: "0.1.0", files: { "config/budgets.yml" => "max: 1\n" })
            write_release(target_root, version: "0.2.0", files: { "config/budgets.yml" => "max: 3\n" })
            write_app(app_root, version: "0.1.0", files: { "config/budgets.yml" => "max: 2\n" })

            _out, _err, status = run_update("0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root)
            expect(status.exitstatus).to eq(1)

            File.write(File.join(app_root, "config/budgets.yml"), partial)
            _out, err, status = run_update("0.2.0", "--root", app_root, "--continue")
            expect(status.exitstatus).to eq(2), "expected a partial marker to block: #{partial.inspect}"
            expect(err).to include("conflict markers")
            expect(File.read(File.join(app_root, "KERNEL_VERSION"))).to eq("0.1.0\n")
          end
        end
      end
    end
  end

  it "ignores a lone setext separator when --continue checks for conflicts" do
    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(base_root, version: "0.1.0", files: { "config/budgets.yml" => "max: 1\n" })
          write_release(target_root, version: "0.2.0", files: { "config/budgets.yml" => "max: 3\n" })
          write_app(
            app_root,
            version: "0.1.0",
            files: {
              "config/budgets.yml" => "max: 2\n",
              "docs/notes.md" => "Adopter notes\n=============\n"
            }
          )

          _out, _err, status = run_update("0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root)
          expect(status.exitstatus).to eq(1)

          File.write(File.join(app_root, "config/budgets.yml"), "max: 2\n")
          _out, err, status = run_update("0.2.0", "--root", app_root, "--continue")
          expect(status).to be_success, err
          expect(File.read(File.join(app_root, "KERNEL_VERSION"))).to eq("0.2.0\n")
        end
      end
    end
  end

  it "ignores conflict-like text in built frontend assets on --continue" do
    Dir.mktmpdir("rafelo-kernel-base-") do |base_root|
      Dir.mktmpdir("rafelo-kernel-target-") do |target_root|
        Dir.mktmpdir("rafelo-kernel-app-") do |app_root|
          write_release(base_root, version: "0.1.0", files: { "config/budgets.yml" => "max: 1\n" })
          write_release(target_root, version: "0.2.0", files: { "config/budgets.yml" => "max: 3\n" })
          write_app(
            app_root,
            version: "0.1.0",
            files: {
              "config/budgets.yml" => "max: 2\n",
              "public/vite/assets/app.js" => "const a = 1;\n<<<<<<< local\n=======\n>>>>>>> target\n"
            }
          )

          _out, _err, status = run_update("0.2.0", "--root", app_root, "--base-source", base_root, "--source", target_root)
          expect(status.exitstatus).to eq(1)

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
