class AddDefaultStatusToBets < ActiveRecord::Migration[6.1]
  def change
    change_column_default :bets, :status, 'pending'
  end
end
