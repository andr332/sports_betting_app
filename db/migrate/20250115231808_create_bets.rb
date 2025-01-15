class CreateBets < ActiveRecord::Migration[6.1]
  def change
    create_table :bets, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid # Set the foreign key to uuid
      t.references :event, null: false, foreign_key: true, type: :uuid
      t.decimal :amount
      t.decimal :odds
      t.string :status

      t.timestamps
    end
  end
end
