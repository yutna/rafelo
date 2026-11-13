# frozen_string_literal: true

module Rafelo
  module Core
    # SEC-11: a return target is read only here, checked as given and once
    # percent-decoded, and accepted only when it stays inside a configured
    # locale. Everything else falls back to that locale's home page.
    class ReturnTo
      CONTROL = /[[:cntrl:]]/
      SCHEME = /\A[a-z][a-z0-9+.-]*:/i

      def self.from(params, locale: I18n.locale)
        new(params[:return_to] || params["return_to"], locale:)
      end

      def initialize(value, locale: I18n.locale)
        @value = value
        @locale = locale.to_s
      end

      def to_s
        return fallback unless configured_locale?
        return fallback unless valid?(@value)
        return fallback unless valid?(decoded(@value))

        @value
      end
      alias to_str to_s

      private

      def fallback
        "/#{@locale}"
      end

      def configured_locale?
        Locales.available.map(&:to_s).include?(@locale)
      end

      def valid?(candidate)
        return false if candidate.blank?
        return false unless candidate.start_with?("/")
        return false if candidate.match?(SCHEME)
        return false if candidate.include?("\\")
        return false if candidate.include?("//")
        return false if candidate.match?(CONTROL)

        path = candidate.split("?", 2).first
        segments = path.split("/", -1)
        return false if segments.any? { |segment| segment == "." || segment == ".." }
        return false if segments[1..].any?(&:empty?)

        Locales.available.map(&:to_s).any? do |locale|
          path == "/#{locale}" || path.start_with?("/#{locale}/")
        end
      end

      def decoded(value)
        URI.decode_www_form_component(value.to_s)
      rescue ArgumentError
        ""
      end
    end
  end
end
