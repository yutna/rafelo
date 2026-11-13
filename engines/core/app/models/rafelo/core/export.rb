# frozen_string_literal: true

module Rafelo
  module Core
    class Export < ActiveRecord::Base
      self.table_name = "core_exports"

      has_one_attached :file

      def formatted_expires_at(locale: I18n.locale)
        DateFormatter.format(expires_at, locale: locale)
      end

      def self.purge_expired
        where("expires_at < ?", Time.current).in_batches(of: 100) do |batch|
          batch.each do |export|
            export.file.purge
            export.destroy
          end
        end
      end
    end
  end
end
