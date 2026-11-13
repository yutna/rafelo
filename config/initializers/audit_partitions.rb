# frozen_string_literal: true

# Partitions are excluded from structure.sql, so every database creates the
# current and next month at boot (OPS-08). Production also runs the scheduled
# maintenance job; this local boot makes a fresh test or development database
# usable immediately.
Rails.application.config.after_initialize do
  next unless Rails.env.local?

  begin
    Rafelo::Core::AuditPartitions.new.ensure!
  rescue ActiveRecord::ActiveRecordError, PG::Error => error
    Rails.logger.warn("audit partitions not ensured at boot: #{error.class}: #{error.message}")
  end
end
