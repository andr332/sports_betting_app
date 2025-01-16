class AddResultToEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :result, :string
  end
end
