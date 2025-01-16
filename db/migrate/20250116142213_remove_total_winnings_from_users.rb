class RemoveTotalWinningsFromUsers < ActiveRecord::Migration[6.1]
  def change
    remove_column :users, :total_winnings, :decimal
  end
end
