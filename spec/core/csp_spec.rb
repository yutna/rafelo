# frozen_string_literal: true

require "rails_helper"

RSpec.describe Rafelo::Core::Csp do
  describe ".report_only" do
    it "defaults a missing config section or key to the enforced policy" do
      expect(described_class.report_only(nil)).to be(false)
      expect(described_class.report_only({})).to be(false)
      expect(described_class.report_only({ report_only: nil })).to be(false)
    end

    it "keeps a boolean" do
      expect(described_class.report_only({ report_only: true })).to be(true)
      expect(described_class.report_only({ report_only: false })).to be(false)
    end

    it "refuses a malformed value instead of guessing" do
      expect { described_class.report_only({ report_only: "sometimes" }) }
        .to raise_error(ArgumentError, /config\/core\.yml csp\.report_only/)
      expect { described_class.report_only([ true ]) }
        .to raise_error(ArgumentError, /config\/core\.yml csp must be a mapping/)
    end
  end
end
