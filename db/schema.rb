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

ActiveRecord::Schema[8.1].define(version: 2026_06_19_010000) do
  create_table "character_achievements", force: :cascade do |t|
    t.integer "character_id", null: false
    t.datetime "created_at", null: false
    t.datetime "earned_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id", "key"], name: "index_character_achievements_on_character_id_and_key", unique: true
    t.index ["character_id"], name: "index_character_achievements_on_character_id"
  end

  create_table "character_event_cooldowns", force: :cascade do |t|
    t.integer "character_id", null: false
    t.datetime "created_at", null: false
    t.string "event_key", null: false
    t.datetime "next_event_at", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id", "event_key"], name: "index_character_event_cooldowns_on_character_id_and_event_key", unique: true
    t.index ["character_id"], name: "index_character_event_cooldowns_on_character_id"
  end

  create_table "characters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "currency", default: 0, null: false
    t.bigint "experience", default: 0, null: false
    t.string "gender", default: "male", null: false
    t.datetime "last_online", default: -> { "CURRENT_TIMESTAMP" }
    t.integer "level", default: 1, null: false
    t.string "name", default: "Wandering Cultivator", null: false
    t.integer "reset", default: 0, null: false
    t.integer "sublevel", default: 1, null: false
    t.bigint "total_experience", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_characters_on_user_id", unique: true
  end

  create_table "game_events", force: :cascade do |t|
    t.integer "character_id", null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "event_key", null: false
    t.datetime "happened_at", null: false
    t.text "metadata", default: "{}", null: false
    t.string "outcome", null: false
    t.integer "qi_delta", default: 0, null: false
    t.integer "related_character_id"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id", "happened_at"], name: "index_game_events_on_character_id_and_happened_at"
    t.index ["character_id"], name: "index_game_events_on_character_id"
    t.index ["related_character_id"], name: "index_game_events_on_related_character_id"
  end

  create_table "inventory_items", force: :cascade do |t|
    t.integer "character_id", null: false
    t.datetime "created_at", null: false
    t.string "equipment_kind", null: false
    t.string "equipment_slot"
    t.integer "inventory_slot"
    t.string "item_type", default: "equipment", null: false
    t.text "metadata", default: "{}", null: false
    t.string "name", null: false
    t.text "power_options", default: "[]", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id", "equipment_slot"], name: "index_inventory_items_on_character_id_and_equipment_slot", unique: true, where: "equipment_slot IS NOT NULL"
    t.index ["character_id", "inventory_slot"], name: "index_inventory_items_on_character_id_and_inventory_slot", unique: true, where: "inventory_slot IS NOT NULL"
    t.index ["character_id"], name: "index_inventory_items_on_character_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.boolean "temporary", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "character_achievements", "characters"
  add_foreign_key "character_event_cooldowns", "characters"
  add_foreign_key "characters", "users"
  add_foreign_key "game_events", "characters"
  add_foreign_key "game_events", "characters", column: "related_character_id"
  add_foreign_key "inventory_items", "characters"
  add_foreign_key "sessions", "users"
end
