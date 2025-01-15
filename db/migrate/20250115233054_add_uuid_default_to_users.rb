class AddUuidDefaultToUsers < ActiveRecord::Migration[6.1]
  def change
    change_column_default :users, :id, from: nil, to: -> { "gen_random_uuid()" }
  end
end
