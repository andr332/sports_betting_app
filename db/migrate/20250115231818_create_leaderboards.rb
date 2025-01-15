class CreateLeaderboards < ActiveRecord::Migration[6.1]
  def change
    create_table :leaderboards, id: :uuid do |t|  # Set the primary key for leaderboards to UUID
      t.references :user, null: false, foreign_key: true, type: :uuid  # Set the foreign key type to uuid
      t.decimal :total_winnings

      t.timestamps
    end
  end
end
