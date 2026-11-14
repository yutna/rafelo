# frozen_string_literal: true

namespace :rafelo do
  namespace :restore do
    desc "Empty core_sessions after a restore; run with the migration role before traffic"
    task prepare: :environment do
      unless ENV["ACME_DATABASE_ROLE"] == "migration"
        abort "rafelo:restore:prepare must run with ACME_DATABASE_ROLE=migration"
      end
      unless ENV["ACME_RESTORE_CONFIRMED"] == "1"
        abort "rafelo:restore:prepare needs ACME_RESTORE_CONFIRMED=1"
      end

      Rafelo::Core::RestorePreparation.new.empty_sessions!
      puts "rafelo:restore:prepare: core_sessions is empty"
    end
  end
end
