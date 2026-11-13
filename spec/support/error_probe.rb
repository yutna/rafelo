# frozen_string_literal: true

class ErrorProbe
  Report = Data.define(:error, :handled, :severity, :context, :source)

  attr_reader :reports

  def initialize
    @reports = []
  end

  def report(error, handled:, severity:, context:, source: nil)
    @reports << Report.new(error: error, handled: handled, severity: severity, context: context, source: source)
  end
end
