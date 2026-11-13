# frozen_string_literal: true

class AddFormatVersionToCoreExports < ActiveRecord::Migration[8.1]
  def change
    add_column :core_exports, :format_version, :integer, null: false, default: 1
  end
end
