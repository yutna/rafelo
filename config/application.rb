require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Rafelo
  class Application < Rails::Application
    def self.dummy_boot_task?
      return false unless defined?(Rake::Task)

      Rake.application.top_level_tasks.any? do |task|
        %w[assets:precompile ci:production_routes].include?(task)
      end
    end

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1
    config.time_zone = "UTC"
    config.active_record.default_timezone = :utc

    if Rails.env.production? && ENV["SECRET_KEY_BASE_DUMMY"].blank?
      if ENV["RAILS_MASTER_KEY"].blank? && ENV["SECRET_KEY_BASE"].blank?
        raise ActiveSupport::EncryptedFile::MissingKeyError.new(
          key_path: Rails.root.join("config/credentials/production.key"), env_key: "RAILS_MASTER_KEY"
        )
      end
    end

    # A real production boot needs the encrypted production credentials. The
    # two dummy-boot tasks read the committed dummy credentials instead
    # (SEC-12, OPS-06).
    config.require_master_key = Rails.env.production? && ENV["SECRET_KEY_BASE_DUMMY"].blank?

    # A dummy boot (assets:precompile in the image build, ci:production_routes)
    # reads the committed dummy credentials; every other process reads
    # config/credentials/production.yml.enc (OPS-06, SEC-12).
    if ENV["SECRET_KEY_BASE_DUMMY"]
      config.credentials.content_path = root.join("config/credentials/dummy.yml.enc")
      config.credentials.key_path = root.join("config/credentials/dummy.key")
      unless dummy_boot_task?
        raise "SECRET_KEY_BASE_DUMMY is only for assets:precompile and ci:production_routes"
      end
    end

    # Audit triggers and partitions cannot be expressed in schema.rb (OPS-08).
    config.active_record.schema_format = :sql
    config.active_record.dump_schema_after_migration = false
    config.after_initialize do
      require "active_record/tasks/database_tasks"
      ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags = [ "--exclude-table=core_audit_events_*" ]
    end

    # Do not put job arguments in the log; jobs carry ids in their own fields
    # and log lines use the allow-list (OPS-01).
    config.active_job.log_arguments = false

    # Refuse a redirect to another host; ReturnTo checks the target first.
    config.action_controller.action_on_open_redirect = :raise

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
