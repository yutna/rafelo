# frozen_string_literal: true

module Rafelo
  module Core
    # One server-side formatter for flash messages and exports (FE-20).
    class DateFormatter
      THAI_MONTHS = %w[
        มกราคม กุมภาพันธ์ มีนาคม เมษายน พฤษภาคม มิถุนายน
        กรกฎาคม สิงหาคม กันยายน ตุลาคม พฤศจิกายน ธันวาคม
      ].freeze

      def self.format(value, locale: I18n.locale)
        date = value.respond_to?(:to_date) ? value.to_date : Date.parse(value.to_s)
        if locale.to_s == "th"
          "#{date.day} #{THAI_MONTHS.fetch(date.month - 1)} #{date.year + 543}"
        else
          date.strftime("%-d %B %Y")
        end
      end
    end
  end
end
