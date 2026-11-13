# frozen_string_literal: true

module Rafelo
  module Core
    class ValidationFailed < ApplicationError
      attr_reader :field_codes

      def initialize(field_codes)
        @field_codes = field_codes.to_h
        super("validation.failed")
      end
    end
  end
end
