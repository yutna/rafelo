# frozen_string_literal: true

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

        expect(described_class.leftover_paths(destination)).to be_empty
        expect { described_class.verify_no_placeholders!(destination) }.not_to raise_error

        expect(File.read(File.join(destination, "KERNEL_VERSION"))).to eq("#{version}\n")
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
        domain_spec = File.read(File.join(destination, "spec", "generators", "domain_generator_spec.rb"))
        expect(domain_spec).to include("lib/rafelo/customers_probe")

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

  describe ".leftover_paths" do
    it "reports a rendered app that still contains the placeholder name" do
      Dir.mktmpdir("rafelo-template-leftover-") do |destination|
        File.write(File.join(destination, "leftover.md"), "Acme still here\n")

        expect(described_class.leftover_paths(destination)).to eq([ "leftover.md" ])
        expect { described_class.verify_no_placeholders!(destination) }
          .to raise_error(ArgumentError, /acme/)
      end
    end
  end
end
