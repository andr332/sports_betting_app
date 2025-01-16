# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2025_01_16_213258) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "bets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "event_id", null: false
    t.decimal "amount"
    t.decimal "odds"
    t.string "status", default: "pending"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "predicted_outcome"
    t.index ["event_id"], name: "index_bets_on_event_id"
    t.index ["user_id"], name: "index_bets_on_user_id"
  end

  create_table "events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "start_time", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.decimal "odds", precision: 10, scale: 2, null: false
    t.string "status", default: "upcoming", null: false
    t.string "result"
    t.check_constraint "(result IS NULL) OR ((result)::text = ANY ((ARRAY['win'::character varying, 'lose'::character varying, 'draw'::character varying])::text[]))", name: "check_result_inclusion"
    t.check_constraint "(status)::text = ANY ((ARRAY['upcoming'::character varying, 'ongoing'::character varying, 'completed'::character varying])::text[])", name: "check_status_inclusion"
    t.check_constraint "odds > (0)::numeric", name: "check_odds_positive"
  end

  create_table "leaderboards", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.decimal "total_winnings"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["user_id"], name: "index_leaderboards_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "password_digest"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "bets", "events"
  add_foreign_key "bets", "users"
  add_foreign_key "leaderboards", "users"
end
