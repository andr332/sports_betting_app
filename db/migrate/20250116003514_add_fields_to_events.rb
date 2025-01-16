class AddFieldsToEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :status, :string, null: false, default: 'upcoming'
  end
end
