# The structure dump creates the audit parent table and trigger; partitions
# are excluded from the dump and created here for every test database.
RSpec.configure do |config|
  config.before(:suite) do
    Rafelo::Core::AuditPartitions.new.ensure!
  rescue ActiveRecord::StatementInvalid
    nil
  end
end
