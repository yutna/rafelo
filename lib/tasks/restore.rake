# frozen_string_literal: true

namespace :rafelo do
  namespace :restore do
    desc "Empty core_sessions after a restore; run with the migration role before traffic"
    task prepare: :environment do
      unless ENV["RAFELO_DATABASE_ROLE"] == "migration"
        abort "rafelo:restore:prepare must run with RAFELO_DATABASE_ROLE=migration"
      end
      unless ENV["RAFELO_RESTORE_CONFIRMED"] == "1"
        abort "rafelo:restore:prepare needs RAFELO_RESTORE_CONFIRMED=1"
      end

      Rafelo::Core::RestorePreparation.new.empty_sessions!
      puts "rafelo:restore:prepare: core_sessions is empty"
    end
  end
end
