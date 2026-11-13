# frozen_string_literal: true

module Rafelo
  module Core
    class LegacyRedirect
      def initialize(module_entry, target_path)
        @module_entry = module_entry
        @target_path = target_path.to_s
      end

      def call(env)
        request = ActionDispatch::Request.new(env)
        locale = request.path_parameters[:locale].presence || Locales.default.to_s
        rest = request.path_parameters[:rest].to_s
        suffix = rest.empty? ? "" : "/#{rest}"
        location = "/#{locale}#{@module_entry.path}#{@target_path}#{suffix}"
        [ 301, { "Location" => location, "Content-Type" => "text/plain" }, [ "Moved Permanently" ] ]
      end
    end
  end
end
