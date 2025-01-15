class CreateEvents < ActiveRecord::Migration[6.1]
  def change
    create_table :events, id: :uuid do |t|  # This sets the primary key to UUID
      t.string :name
      t.datetime :start_time

      t.timestamps
    end
  end
end
