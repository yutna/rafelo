# frozen_string_literal: true

module Rafelo
  module Core
    class ApplicationError < StandardError
      attr_reader :code

      def initialize(code, message = nil)
        @code = code.to_s
        super(message || I18n.t(entry.fetch("i18n_key"), default: @code))
      end

      def status = entry.fetch("status")
      def retryable? = entry.fetch("retryable")
      def i18n_key = entry.fetch("i18n_key")

      private

      def entry
        @entry ||= ErrorCatalog.fetch(@code)
      end
    end
  end
end
