# frozen_string_literal: true

module Rafelo
  module Core
    # The signed id in the URL is the authorization for a finished export
    # (BE-18): the owner already passed ExportPolicy at click time, and the
    # record cannot be found without a valid, unexpired signature.
    class ExportFilePolicy < BasePolicy
      def show? = true
    end
  end
end
