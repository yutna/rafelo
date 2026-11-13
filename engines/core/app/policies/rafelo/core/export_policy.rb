# frozen_string_literal: true

module Rafelo
  module Core
    class ExportPolicy < BasePolicy
      def show? = record.viewer_id == user&.id.to_s
    end
  end
end
