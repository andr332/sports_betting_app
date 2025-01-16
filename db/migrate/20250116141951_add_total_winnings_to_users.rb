class AddTotalWinningsToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :total_winnings, :decimal
  end
end
