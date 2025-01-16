class CreateResultTypes < ActiveRecord::Migration[6.1]
  def change
    create_table :result_types do |t|
      t.string :name

      t.timestamps
    end
    add_index :result_types, :name, unique: true
  end
end
