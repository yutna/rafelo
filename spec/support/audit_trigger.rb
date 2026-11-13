# The schema dump cannot represent plpgsql triggers, so a test database loaded
# from schema.rb gets the trigger from the migration's DDL here.
RSpec.configure do |config|
  config.before(:suite) do
    connection = ActiveRecord::Base.connection
    connection.execute(<<~SQL)
      CREATE OR REPLACE FUNCTION rafelo_core_audits_append_only() RETURNS trigger AS $$
      BEGIN
        RAISE EXCEPTION 'core_audits is append-only';
      END;
      $$ LANGUAGE plpgsql;
      DROP TRIGGER IF EXISTS rafelo_core_audits_no_update ON core_audits;
      CREATE TRIGGER rafelo_core_audits_no_update
        BEFORE UPDATE OR DELETE ON core_audits
        FOR EACH ROW EXECUTE FUNCTION rafelo_core_audits_append_only();
    SQL
  rescue ActiveRecord::StatementInvalid
    nil
  end
end
