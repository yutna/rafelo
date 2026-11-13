# frozen_string_literal: true

# Example of the expand/contract migration shape (BE-22): the index build runs
# outside the DDL transaction and concurrently, so a deploy does not lock the
# table. The migration is a fixture and is not applied by the test suite.
class AddIndexToInvoicesNumber < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :invoices, :number, algorithm: :concurrently
  end
end
