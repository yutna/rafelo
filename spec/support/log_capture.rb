# frozen_string_literal: true

require "json"

module LogCapture
  # Lograge writes through its own logger. Replace it for one block and parse
  # the JSON lines, so a spec sees exactly what production writes.
  def capture_lograge
    output = StringIO.new
    logger = Logger.new(output)
    logger.formatter = ->(_severity, _time, _program, message) { "#{message}\n" }
    previous = Lograge.logger
    Lograge.logger = logger
    yield
    output.string.lines.filter_map do |line|
      JSON.parse(line)
    rescue JSON::ParserError
      nil
    end
  ensure
    Lograge.logger = previous
  end

  def raw_lograge_output
    output = StringIO.new
    logger = Logger.new(output)
    logger.formatter = ->(_severity, _time, _program, message) { "#{message}\n" }
    previous = Lograge.logger
    Lograge.logger = logger
    yield
    output.string
  ensure
    Lograge.logger = previous
  end
end

RSpec.configure do |config|
  config.include LogCapture
end
