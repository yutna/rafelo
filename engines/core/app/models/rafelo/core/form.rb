# frozen_string_literal: true

module Rafelo
  module Core
    # Shape-only form object. Business rules stay upstream; this validates
    # presence, format and length and translates codes for Inertia (BE-13).
    class Form
      include ActiveModel::Model
      include ActiveModel::Attributes

      attribute :token, :string

      def payload
        attributes.deep_symbolize_keys.except(:token).compact
      end

      def error_messages
        valid?
        errors.details.each_with_object({}) do |(attribute, entries), out|
          key = field_key(attribute)
          out[key] = entries.map { |entry| field_message(entry[:error], entry) }.join(", ")
        end
      end

      def translate(field_codes)
        field_codes.to_h.each_with_object({}) do |(field, code), out|
          key = field.to_s == "base" || known_field?(field) ? field_key(field) : "base"
          out[key] = field_message(code)
        end
      end

      private

      def field_key(attribute)
        attribute.to_s.camelize(:lower)
      end

      def known_field?(field)
        self.class.attribute_names.include?(field.to_s.underscore)
      end

      def field_message(code, entry = {})
        I18n.t(
          "core.errors.fields.#{code}",
          default: I18n.t("core.errors.fields.invalid"),
          count: entry[:count],
          max: entry[:max]
        )
      end
    end
  end
end
