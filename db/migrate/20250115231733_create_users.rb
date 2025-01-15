class CreateUsers < ActiveRecord::Migration[6.1]
  def change
    create_table :users, id: false do |t|
      t.uuid :id, primary_key: true  # Define UUID as the primary key
      t.string :name
      t.string :email
      t.string :password_digest

      t.timestamps
    end
  end
end
