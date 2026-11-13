# frozen_string_literal: true

module Rafelo
  module Core
    ListQuery = Data.define(:page, :per_page, :sort, :direction, :filters, :cursor) do
      DEFAULT_PER_PAGE = 25
      MAX_PER_PAGE = 100
      MAX_FILTER_LENGTH = 200
      MAX_MULTI_FILTER = 10
      MAX_CURSOR_LENGTH = 200

      def self.max_per_page = MAX_PER_PAGE

      def self.from(params, sort:, filters: {}, default_sort: nil, default_direction: "asc")
        page = integer(params[:page]) || 1
        page = 1 if page < 1
        per_page = integer(params[:per_page]) || DEFAULT_PER_PAGE
        per_page = DEFAULT_PER_PAGE if per_page < 1
        per_page = [ per_page, MAX_PER_PAGE ].min

        sort_value = params[:sort].is_a?(String) && sort.map(&:to_s).include?(params[:sort]) ? params[:sort] : default_sort
        direction = %w[asc desc].include?(params[:direction]) ? params[:direction] : default_direction
        cursor = params[:cursor].is_a?(String) && params[:cursor].length <= MAX_CURSOR_LENGTH ? params[:cursor] : nil

        new(
          page: page,
          per_page: per_page,
          sort: sort_value,
          direction: direction,
          filters: filters_from(params, filters),
          cursor: cursor
        )
      end

      def self.integer(value)
        return value if value.is_a?(Integer)
        return nil unless value.is_a?(String) && value.match?(/\A-?\d+\z/)

        value.to_i
      end

      def self.filters_from(params, filters)
        filters.each_with_object({}) do |(key, spec), result|
          value = params[key]
          if spec.is_a?(Array)
            next unless scalar?(value) && spec.map(&:to_s).include?(value)
          elsif spec.is_a?(Hash)
            limit = spec.fetch(:multiple, 1)
            values = value.is_a?(Array) ? value : [ value ]
            next unless values.length <= limit
            next unless values.all? { |entry| scalar?(entry) }
            allowed = spec[:values]
            next if allowed && !values.all? { |entry| allowed.map(&:to_s).include?(entry) }
            value = spec.fetch(:multiple, nil) ? values : values.first
          else
            next unless scalar?(value)
            next if spec && !Array(spec).map(&:to_s).include?(value)
          end
          result[key.to_s] = value
        end
      end

      def self.scalar?(value)
        value.is_a?(String) && value.length <= MAX_FILTER_LENGTH
      end
    end
  end
end
