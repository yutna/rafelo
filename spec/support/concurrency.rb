require "concurrent"

module ConcurrencyHelpers
  def barrier(count)
    Concurrent::CyclicBarrier.new(count)
  end

  def latch
    Concurrent::CountDownLatch.new
  end
end

module ConcurrencyTransactional
  # The :concurrency tag itself keeps each example outside the transactional
  # wrapper, so a thread sees the others' commits (TS-10).
  def use_transactional_tests = false
end

RSpec.configure do |config|
  config.include ConcurrencyHelpers, :concurrency
  config.include ConcurrencyTransactional, :concurrency

  config.before(:each, :concurrency) do |example|
    tables = Array(example.metadata[:truncate])
    ActiveRecord::Base.connection.truncate_tables(*tables) if tables.any?
  end

  config.after(:each, :concurrency) do |example|
    tables = Array(example.metadata[:truncate])
    ActiveRecord::Base.connection.truncate_tables(*tables) if tables.any?
  end
end
