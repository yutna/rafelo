# frozen_string_literal: true

module Rafelo
  module Core
    class Export < ActiveRecord::Base
      FORMAT_VERSION = 1
      READABLE_FORMAT_VERSIONS = [ FORMAT_VERSION ].freeze
      DOWNLOAD_PURPOSE = :export_download
      DOWNLOAD_URL_TTL = 5.minutes

      self.table_name = "core_exports"

      has_one_attached :file

      scope :readable_format, -> { where(format_version: READABLE_FORMAT_VERSIONS) }

      def self.build_for(viewer:, filename:)
        create!(
          viewer_id: viewer.id.to_s,
          filename: filename,
          expires_at: Rails.application.config.x.exports.ttl_seconds.seconds.from_now
        )
      end

      def formatted_expires_at(locale: I18n.locale)
        DateFormatter.format(expires_at, locale: locale)
      end

      # A bearer credential for one file, valid for minutes. It is created at
      # click time and never stored, so a copied link dies on its own (BE-18).
      def signed_download_id(expires_in: DOWNLOAD_URL_TTL)
        signed_id(purpose: DOWNLOAD_PURPOSE, expires_in: expires_in)
      end

      def self.find_by_signed_download_id(signed_id)
        find_signed(signed_id, purpose: DOWNLOAD_PURPOSE)
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
