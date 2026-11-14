# frozen_string_literal: true

require "fileutils"
require "open3"
require "tmpdir"
require "rails_helper"
require_relative "../../template/lib/rafelo_template"

RSpec.describe RafeloTemplate, "payload rendering" do
  let(:source_root) { File.expand_path("../..", __dir__) }
  let(:version) { File.read(File.join(source_root, "VERSION")).strip }
  let(:full_flags) do
    described_class::REQUIRED_FLAGS + %w[-d postgresql]
  end

  describe ".assert_flags!" do
    it "accepts the flag set GEN-07 requires" do
      expect(described_class.assert_flags!(full_flags)).to be(true)
      expect(described_class.assert_flags!(full_flags - [ "-d", "postgresql" ] + [ "--database=postgresql" ])).to be(true)
    end

    it "stops when any required flag is missing" do
      described_class::REQUIRED_FLAGS.each do |flag|
        expect { described_class.assert_flags!(full_flags - [ flag ]) }
          .to raise_error(ArgumentError, /missing/)
      end

      expect { described_class.assert_flags!(full_flags - [ "-d", "postgresql" ]) }
        .to raise_error(ArgumentError, /postgresql/)
    end
  end

  describe "reserved names" do
    it "refuses every reserved name before writing anything" do
      %w[core design_system rafelo engines app example_orders example_customers].each do |name|
        Dir.mktmpdir("rafelo-template-reserved-") do |destination|
          expect do
            described_class.render!(
              source_root: source_root,
              destination: destination,
              app_name: name,
              version: version
            )
          end.to raise_error(ArgumentError, /reserved namespace/)
          expect(Dir.children(destination)).to be_empty
        end
      end
    end

    it "refuses a name that is already a constant before writing anything" do
      Dir.mktmpdir("rafelo-template-constant-") do |destination|
        expect do
          described_class.render!(
            source_root: source_root,
            destination: destination,
            app_name: "string",
            version: version
          )
        end.to raise_error(ArgumentError, /already a constant/)
        expect(Dir.children(destination)).to be_empty
      end
    end
  end

  describe "a rendered fixture app" do
    it "copies the payload, renders the namespace, writes KERNEL_VERSION and commits a clean tree" do
      Dir.mktmpdir("rafelo-template-app-") do |destination|
        written = described_class.render!(
          source_root: source_root,
          destination: destination,
          app_name: "smoke_shop",
          version: version
        )
        described_class.write_kernel_version!(destination: destination, version: version)
        described_class.write_app_version!(destination: destination)
        FileUtils.mkdir_p(File.join(destination, "config"))
        File.write(File.join(destination, "config", "master.key"), "0" * 32)
        described_class.write_production_credentials!(destination: destination)

        expect(described_class.leftover_paths(destination)).to be_empty
        expect { described_class.verify_no_placeholders!(destination, app_name: "smoke_shop") }.not_to raise_error

        expect(File.read(File.join(destination, "KERNEL_VERSION"))).to eq("#{version}\n")
        expect(File.read(File.join(destination, "VERSION"))).to eq("#{described_class::APP_VERSION}\n")
        expect(written).to include("config/application.rb", "engines/core/lib/rafelo/core/engine.rb")
        expect(written).not_to include("template/template.rb", "spec/template/app_name_spec.rb", "docs/development/ai-files.md")

        application = File.read(File.join(destination, "config", "application.rb"))
        expect(application).to include("module SmokeShop")
        expect(application).not_to include("module Rafelo")

        expect(File.read(File.join(destination, "app", "frontend", "lib", "app_metadata.ts")))
          .to include('name: "SmokeShop"')
        expect(File.read(File.join(destination, "AGENTS.md"))).to start_with("# AGENTS.md — SmokeShop")
        expect(File.read(File.join(destination, "README.md"))).to start_with("# SmokeShop")
        expect(File.read(File.join(destination, "spec", "requests", "home_spec.rb")))
          .to include('"message":"SmokeShop"')

        page_spec = File.read(File.join(destination, "spec", "generators", "page_generator_spec.rb"))
        expect(page_spec).to include("app/controllers/smoke_shop/billing")
        expect(page_spec).to include("Rafelo::Core::Form")
        expect(page_spec).to include("generators/rafelo/page_generator")
        rename_spec = File.read(File.join(destination, "spec", "generators", "rename_module_generator_spec.rb"))
        expect(rename_spec).to include("lib/smoke_shop/billing")
        expect(rename_spec).to include("module SmokeShop::Billing")
        module_spec = File.read(File.join(destination, "spec", "generators", "module_generator_spec.rb"))
        expect(module_spec).to include("smoke_shop_billing_probe.gemspec")
        domain_spec = File.read(File.join(destination, "spec", "generators", "domain_generator_spec.rb"))
        expect(domain_spec).to include("smoke_shop_customers_probe.gemspec")
        expect(domain_spec).to include("lib/smoke_shop/customers_probe")


        expect(File.read(File.join(destination, "package.json"))).to include('"name": "smoke_shop"')
        database = File.read(File.join(destination, "config", "database.yml"))
        expect(database).to include("smoke_shop_development", "smoke_shop_production", "smoke_shop_runtime", "SMOKE_SHOP_DATABASE_ROLE")
        deploy = File.read(File.join(destination, "config", "deploy.yml"))
        expect(deploy).to include("service: smoke_shop", "image: smoke_shop", "SMOKE_SHOP_API_BASE_URL")
        expect(File.read(File.join(destination, ".env.ci.production"))).to include("SMOKE_SHOP_API_BASE_URL")
        expect(File.read(File.join(destination, "config", "initializers", "session_store.rb"))).to include("smoke_shop_session")

        backend_docs = File.read(File.join(destination, "docs", "architecture", "02_backend.md"))
        expect(backend_docs).to include("Rafelo::Core")
        expect(backend_docs).to include("SMOKE_SHOP_API_BASE_URL")
        expect(backend_docs).not_to include("SmokeShop::Core")
        expect(File.read(File.join(destination, "docs", "architecture", "01_architecture.md"))).to include("Rafelo::DesignSystem")
        expect(File.read(File.join(destination, "docs", "architecture", "08_generators.md"))).to include("SmokeShop::Billing")
        deployment_docs = File.read(File.join(destination, "docs", "deployment.md"))
        expect(deployment_docs).to include("docker build -t smoke_shop .")
        expect(deployment_docs).to include("--name smoke_shop")
        expect(deployment_docs).to include("rafelo:module")
        expect(deployment_docs).not_to include("docker build -t rafelo")
        backup_docs = File.read(File.join(destination, "docs", "operations", "backup-restore.md"))
        expect(backup_docs).to include("[smoke_shop]", "/backup/smoke_shop", "--stanza=smoke_shop")
        expect(backup_docs).to include("RESTORE_DATABASE_URL=postgres://.../smoke_shop")
        expect(backup_docs).to include("rafelo:restore:prepare")
        expect(backup_docs).not_to include("/backup/rafelo", "--stanza=rafelo")
        expect(File.read(File.join(destination, ".github", "workflows", "ci.yml")))
          .to include("docker build -t smoke_shop-ci .")
        expect(File).to exist(File.join(destination, "spec", "fixtures", "formats", "v0.1.0", "sessions.json"))
        expect(File).to exist(File.join(destination, "config", "credentials", "production.yml.enc"))
        expect(File).not_to exist(File.join(destination, "config", "credentials", "production.key"))

        kernel = File.read(File.join(destination, "engines", "core", "lib", "rafelo", "core", "engine.rb"))
        expect(kernel).to include("module Rafelo")
        expect(kernel).not_to include("SmokeShop")

        kernel_initializer = File.read(File.join(destination, "config", "initializers", "modules.rb"))
        expect(kernel_initializer).to include("engines/core/app/models/rafelo/core/modules")

        if Dir.exist?(File.join(source_root, "engines", "example_orders"))
          example = File.read(File.join(destination, "engines", "example_orders", "lib", "rafelo", "example_orders", "engine.rb"))
          expect(example).to include("module Rafelo")
          expect(example).to include("ExampleOrders")
        end

        expect(File).to exist(File.join(destination, ".github", "workflows", "ci.yml"))
        expect(File).not_to exist(File.join(destination, ".github", "workflows", "pr-check.yml"))
        expect(File).not_to exist(File.join(destination, ".github", "workflows", "issue-check.yml"))
        expect(File.read(File.join(destination, ".github", "CODEOWNERS"))).to include("@OWNER")

        %w[add-read-page add-write-action add-module add-design-system-component].each do |skill|
          expect(File).to exist(File.join(destination, ".opencode", "skills", skill, "SKILL.md"))
        end

        expect(Dir).not_to exist(File.join(destination, "docs", "development"))
        expect(Dir).not_to exist(File.join(destination, "spec", "template"))
        expect(Dir).not_to exist(File.join(destination, "template"))

        described_class.commit!(destination: destination)

        author, status = Open3.capture2("git", "-C", destination, "log", "-1", "--format=%an <%ae>")
        expect(status).to be_success
        expect(author.strip).to eq("#{described_class::TEMPLATE_AUTHOR_NAME} <#{described_class::TEMPLATE_AUTHOR_EMAIL}>")

        status_output, status = Open3.capture2("git", "-C", destination, "status", "--porcelain", "--untracked-files=all")
        expect(status).to be_success
        expect(status_output).to be_empty
      end
    end
  end


  describe "the documented acme app name" do
    it "is accepted without treating the app's own name as a placeholder" do
      Dir.mktmpdir("rafelo-template-acme-") do |destination|
        expect do
          described_class.render!(
            source_root: source_root,
            destination: destination,
            app_name: "acme",
            version: version
          )
        end.not_to raise_error

        expect(File.read(File.join(destination, "config", "application.rb"))).to include("module Acme")
        expect(File.read(File.join(destination, "package.json"))).to include('"name": "acme"')
        expect { described_class.verify_no_placeholders!(destination, app_name: "acme") }.not_to raise_error
      end
    end
  end

  describe ".leftover_paths" do
    it "reports a rendered app that still contains the placeholder name" do
      Dir.mktmpdir("rafelo-template-leftover-") do |destination|
        File.write(File.join(destination, "leftover.md"), "Acme still here\n")

        expect(described_class.leftover_paths(destination)).to eq([ "leftover.md" ])
        expect { described_class.verify_no_placeholders!(destination, app_name: "smoke_shop") }
          .to raise_error(ArgumentError, /acme/)
      end
    end
  end
end
