# frozen_string_literal: true

require "rails_helper"
require_relative "../../template/lib/rafelo_template"

RSpec.describe RafeloTemplate do
  describe ".namespace" do
    it "camelizes one-word and two-word app names" do
      expect(described_class.namespace("acme")).to eq("Acme")
      expect(described_class.namespace("smoke_shop")).to eq("SmokeShop")
      expect(described_class.namespace("smoke-shop")).to eq("SmokeShop")
    end
  end

  describe ".validate!" do
    it "returns the namespace for an available name" do
      expect(described_class.validate!("smoke_shop")).to eq("SmokeShop")
    end

    it "refuses every reserved camelized name" do
      %w[core design_system rafelo engines app example_orders example_customers].each do |name|
        expect { described_class.validate!(name) }.to raise_error(ArgumentError, /reserved namespace/)
      end
    end

    it "refuses a name that is already a constant" do
      expect { described_class.validate!("string") }.to raise_error(ArgumentError, /already a constant/)
    end
  end
end
