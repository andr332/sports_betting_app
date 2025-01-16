class AddTotalWinningsToLeaderboards < ActiveRecord::Migration[6.1]
  def change
    change_column_default :leaderboards, :total_winnings, 0.0
    change_column_null :leaderboards, :total_winnings, false, 0.0
  end
end
