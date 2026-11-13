# frozen_string_literal: true

require "digest"

module Rafelo
  module Core
    class Session < ActiveRecord::Base
      self.table_name = "core_sessions"

      encrypts :access_token, :refresh_token

      def self.start(viewer:, access_token:, refresh_token:, access_expires_at:, locale: Locales.default, ttl: 12.hours, grants: [])
        token = SecureRandom.urlsafe_base64(32)
        session = create!(
          token_digest: digest(token),
          viewer_id: viewer.id.to_s,
          viewer_name: viewer.respond_to?(:name) ? viewer.name.to_s : nil,
          access_token: access_token,
          refresh_token: refresh_token,
          access_expires_at: access_expires_at,
          expires_at: ttl.from_now,
          locale: locale,
          permission_grants: grants,
          grant_digest: Digest::SHA256.hexdigest(Array(grants).map(&:to_s).sort.join(",")),
          grants_refreshed_at: Time.current,
          last_seen_at: Time.current
        )
        [ session, token ]
      end

      def self.digest(token)
        Digest::SHA256.hexdigest(token.to_s)
      end

      def self.find_by_token(token)
        find_by(token_digest: digest(token))
      end

      def viewer
        Viewer.new(id: viewer_id, name: viewer_name.to_s)
      end

      def permission_set
        PermissionSet.new(permission_grants)
      end

      def grants_stale?
        grants_refreshed_at.nil? || grants_refreshed_at < 5.minutes.ago
      end

      def replace_grants!(grants)
        update!(permission_grants: grants, grants_refreshed_at: Time.current)
      end

      def touch_seen!
        update_column(:last_seen_at, Time.current)
      end

      def self.sweep
        where("expires_at < ?", Time.current).delete_all
      end

      def claim_refresh!(timeout:)
        claimed = self.class
          .where(id: id, refresh_version: refresh_version)
          .where("refreshing_since IS NULL OR refreshing_since < now() - make_interval(secs => ?)", timeout)
          .update_all("refresh_version = refresh_version + 1, refreshing_since = now()")
          .positive?
        return unless claimed

        begin
          reload
        rescue ActiveRecord::RecordNotFound
          raise ApplicationError.new("auth.expired")
        end
        refresh_version
      end

      def complete_refresh!(version:, access_token:, refresh_token:, access_expires_at:, grants:)
        with_lock do
          next false unless refresh_version == version

          update!(
            access_token: access_token,
            refresh_token: refresh_token,
            access_expires_at: access_expires_at,
            refreshing_since: nil,
            permission_grants: grants,
            grant_digest: grant_digest_for(grants),
            grants_refreshed_at: Time.current
          )
          true
        end
      end

      def fail_refresh!(version:)
        self.class
          .where(id: id, refresh_version: version)
          .update_all(refreshing_since: nil)
      end

      def grant_digest_for(grants)
        Digest::SHA256.hexdigest(Array(grants).map(&:to_s).sort.join(","))
      end

      def serializable_hash(options = nil)
        options = (options || {}).merge(
          except: Array(options&.fetch(:except, nil)) + %i[access_token refresh_token token_digest]
        )
        super(options)
      end
    end
  end
end
