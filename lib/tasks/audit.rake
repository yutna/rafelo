# frozen_string_literal: true

namespace :rafelo do
  namespace :audit do
    desc "Ensure the current and next audit month partitions and the DEFAULT partition"
    task partitions: :environment do
      Rafelo::Core::AuditPartitions.new.ensure!
      puts "rafelo:audit:partitions: #{Rafelo::Core::AuditPartitions.new.partitions.keys.sort.join(", ")}"
    end
  end
end
