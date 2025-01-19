class AddDefaultBalanceToUsers < ActiveRecord::Migration[6.1]
  def change
    change_column_default :users, :balance, 1000
  end
end
