# frozen_string_literal: true

module Rafelo
  module Core
    class ExportPolicy < BasePolicy
      def show? = record.viewer_id == user&.viewer&.id.to_s
    end
  end
end
