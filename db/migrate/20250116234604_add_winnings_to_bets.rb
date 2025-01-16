class AddWinningsToBets < ActiveRecord::Migration[6.1]
  def change
    add_column :bets, :winnings, :decimal
  end
end
