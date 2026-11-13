# frozen_string_literal: true

module Rafelo
  module Core
    # The migration connection owns the tables and may create or drop audit
    # partitions. The web and job processes never use it (OPS-08).
    class MigrationRecord < ActiveRecord::Base
      self.abstract_class = true

      establish_connection :migration if Rails.env.production?
    end
  end
end
