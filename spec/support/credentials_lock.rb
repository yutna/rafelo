# frozen_string_literal: true

# Parallel RSpec processes share one encrypted production file. A test that
# swaps it (the production boot harness) and a test that reads it (the deploy
# preflight) take this lock, so one cannot observe the other's file (BE-08,
# SEC-07).
module CredentialsLock
  PATH = Rails.root.join("tmp", "credentials.lock")

  def self.synchronize
    FileUtils.mkdir_p(PATH.dirname)
    File.open(PATH, File::RDWR | File::CREAT, 0o644) do |file|
      file.flock(File::LOCK_EX)
      yield
    end
  end
end
