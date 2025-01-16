class AddOddsToEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :events, :odds, :decimal, precision: 10, scale: 2
  end
end
