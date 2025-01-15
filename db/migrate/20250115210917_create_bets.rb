class CreateBets < ActiveRecord::Migration[6.1]
  def change
    create_table :bets do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.decimal :amount
      t.decimal :odds
      t.string :status

      t.timestamps
    end
  end
end
