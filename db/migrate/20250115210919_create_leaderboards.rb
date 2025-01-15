class CreateLeaderboards < ActiveRecord::Migration[6.1]
  def change
    create_table :leaderboards do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :total_winnings

      t.timestamps
    end
  end
end
