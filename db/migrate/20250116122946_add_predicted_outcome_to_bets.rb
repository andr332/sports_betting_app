class AddPredictedOutcomeToBets < ActiveRecord::Migration[6.1]
  def change
    add_column :bets, :predicted_outcome, :string
  end
end
