# frozen_string_literal: true

require "rails_helper"
require "yaml"

# The production-image job boots the final image with throwaway credentials.
# They must never touch the tracked config/credentials/production.yml.enc
# (BE-08, SEC-07). The repository and the payload run the same proof.
RSpec.describe "Production image workflow" do
  %w[.github/workflows/ci.yml template/.github/workflows/ci.yml].each do |path|
    describe path do
      let(:jobs) { YAML.safe_load_file(Rails.root.join(path), aliases: true).fetch("jobs") }
      let(:job) { jobs.fetch("production-image") }
      let(:steps) { job.fetch("steps") }

      def step(name)
        steps.find { |candidate| candidate["name"] == name }
      end

      def step_names
        steps.map { |candidate| candidate["name"] }
      end

      it "runs on a change to every production-boot input" do
        trigger = jobs.fetch("production-image-needed").fetch("steps")
          .find { |candidate| candidate["name"] == "Decide whether the production image build runs" }
          .fetch("run")

        %w[
          config/application\.rb
          config/environments/production\.rb
          config/database\.yml
          config/storage\.yml
          config/initializers/.*\.rb
          config/puma\.rb
          config/routes\.rb
          bin/docker-entrypoint
          package(-lock)?\.json
          \.github/workflows/ci\.yml
        ].each do |input|
          expect(trigger).to include(input)
        end
      end

      it "runs against a real Postgres for the boot" do
        expect(job.dig("services", "postgres", "image")).to include("postgres")
        expect(job.dig("services", "postgres", "ports")).to include("5432:5432")
      end

      it "encrypts the throwaway credentials outside the workspace" do
        writer = step("Write throwaway production credentials")

        expect(writer).not_to be_nil
        expect(writer.fetch("run")).to match(%r{config_path: "/tmp/[a-z_]+-production\.yml\.enc"})
        expect(writer.fetch("run")).not_to include('config_path: "config/credentials/')
      end

      it "mounts the temporary credentials into both database and boot containers" do
        writer = step("Write throwaway production credentials").fetch("run")
        encrypted = writer[/config_path: "([^"]+)"/, 1]
        mount = "-v #{encrypted}:/rails/config/credentials/production.yml.enc:ro"

        [ "Prepare the image database", "Boot the production image and check /up" ].each do |name|
          expect(step(name).fetch("run")).to include(mount)
        end
      end

      it "prepares the image database and boots the server to answer /up" do
        prepare = step("Prepare the image database").fetch("run")
        boot = step("Boot the production image and check /up").fetch("run")

        roles = step("Create the runtime and migration roles").fetch("run")
        expect(prepare).to include("./bin/rails db:prepare")
        expect(prepare).to include("ACME_DATABASE_ROLE=migration")
        expect(step("Check psql in the image").fetch("run")).to include("psql --version")
        expect(roles).to include("script/ops/database_roles.sql")
        expect(roles).to include("-v runtime_password=postgres -v migration_password=postgres")
        expect(step_names.index("Prepare the image database"))
          .to be < step_names.index("Create the runtime and migration roles")
        expect(step_names.index("Create the runtime and migration roles"))
          .to be < step_names.index("Boot the production image and check /up")
        expect(boot).to include("-e DB_USER=acme_runtime -e DB_PASSWORD=postgres")
        expect(boot).to include("-e DB_MIGRATION_USER=acme_migrator -e DB_MIGRATION_PASSWORD=postgres")
        expect(boot).to include("-e SOLID_QUEUE_IN_PUMA=true")
        expect(boot).not_to include("./bin/rails server -b")
        expect(boot).to match(/^\s+(?:rafelo|acme)-ci\s*$/)
        expect(boot).to include("-e HTTP_PORT=8080")
        expect(boot).to include('grep -F "rafelo:audit:partitions:" >/dev/null')
        expect(boot).to include('grep -F "SolidQueue-" >/dev/null')
        expect(boot).not_to include("grep -Fq")
        expect(boot).to include(
          "curl -fsS --connect-timeout 2 --max-time 5 http://127.0.0.1:8080/up"
        )
        expect(step("Remove the boot container").fetch("if")).to eq("always()")
      end

      it "proves the tracked credentials file is unchanged after the build" do
        expect(step("Verify the tracked production credentials are untouched").fetch("run"))
          .to include("git diff --exit-code -- config/credentials/production.yml.enc")
        expect(step_names.index("Write throwaway production credentials"))
          .to be < step_names.index("Build the production image")
        expect(step_names.index("Verify the tracked production credentials are untouched"))
          .to be > step_names.index("Build the production image")
      end
    end
  end
end
