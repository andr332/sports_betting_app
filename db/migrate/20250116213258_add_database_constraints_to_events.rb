class AddDatabaseConstraintsToEvents < ActiveRecord::Migration[6.1]
  def change
    # Adding NOT NULL constraints to fields that must not be null
    change_column_null :events, :name, false
    change_column_null :events, :start_time, false
    change_column_null :events, :odds, false
    change_column_null :events, :status, false

    # Adding a CHECK constraint to ensure odds > 0
    execute "ALTER TABLE events ADD CONSTRAINT check_odds_positive CHECK (odds > 0)"

    # Adding a CHECK constraint to ensure status is one of the allowed values
    execute "ALTER TABLE events ADD CONSTRAINT check_status_inclusion CHECK (status IN ('upcoming', 'ongoing', 'completed'))"

    # Adding a CHECK constraint to ensure result is either NULL or one of 'win', 'lose', 'draw'
    execute "ALTER TABLE events ADD CONSTRAINT check_result_inclusion CHECK (result IS NULL OR result IN ('win', 'lose', 'draw'))"
  end
end
