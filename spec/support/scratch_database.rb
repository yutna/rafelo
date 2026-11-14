# frozen_string_literal: true

require "pg"
require "securerandom"

# A throwaway PostgreSQL database for the OPS-06/OPS-08 role and migration
# specs. The specs need a superuser to run the role script and create roles;
# in an environment without one they skip instead of weakening the checks.
class ScratchDatabase
  attr_reader :name, :admin

  def initialize(prefix)
    @config = ActiveRecord::Base.connection_db_config.configuration_hash
    @name = "#{prefix}_#{Process.pid}_#{SecureRandom.hex(4)}"
    @admin = PG.connect(connection_options(@config[:database]))
  end

  def supported?
    superuser?
  rescue PG::Error
    false
  end

  def create!
    @admin.exec("CREATE DATABASE #{@admin.escape_identifier(name)}")
  end

  def connect
    PG.connect(connection_options(name))
  end

  def options
    connection_options(name)
  end

  def drop!
    @admin.exec("DROP DATABASE IF EXISTS #{@admin.escape_identifier(name)} WITH (FORCE)")
  end

  def drop_roles!(roles)
    roles.each do |role|
      @admin.exec("DROP ROLE IF EXISTS #{@admin.escape_identifier(role)}")
    end
  end

  def close
    @admin.close unless @admin.finished?
  end

  private

  def superuser?
    @admin.exec("SELECT rolsuper FROM pg_roles WHERE rolname = current_user").getvalue(0, 0) == "t"
  end

  def connection_options(database)
    options = {
      host: @config[:host] || ENV.fetch("DB_HOST", "localhost"),
      port: @config[:port] || ENV.fetch("DB_PORT", 5432),
      dbname: database,
      user: @config[:username] || ENV.fetch("DB_USER", "postgres")
    }
    password = @config[:password] || ENV["DB_PASSWORD"]
    options[:password] = password if password
    options
  end
end
