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

ActiveRecord::Schema[8.1].define(version: 2026_07_06_002000) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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

  create_table "character_meridians", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.integer "character_id", null: false
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.integer "opened_subpoints", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["character_id", "active"], name: "index_character_meridians_on_character_id_and_active"
    t.index ["character_id", "key"], name: "index_character_meridians_on_character_id_and_key", unique: true
    t.index ["character_id"], name: "index_character_meridians_on_character_id"
  end

  create_table "characters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "currency", default: 0, null: false
    t.integer "current_health"
    t.datetime "daily_reward_claimed_at"
    t.bigint "donation_currency", default: 0, null: false
    t.bigint "experience", default: 0, null: false
    t.string "gender", default: "male", null: false
    t.datetime "health_recovered_at"
    t.datetime "last_online", default: -> { "CURRENT_TIMESTAMP" }
    t.integer "level", default: 1, null: false
    t.string "name", default: "Wandering Cultivator", null: false
    t.integer "reset", default: 0, null: false
    t.bigint "sect_contribution", default: 0, null: false
    t.string "sect_key"
    t.integer "sect_rank", default: 0, null: false
    t.datetime "sect_task_completed_at"
    t.datetime "sparring_available_at"
    t.integer "sparring_points", default: 3, null: false
    t.datetime "sparring_recovered_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.integer "spirit_expedition_duration_hours"
    t.datetime "spirit_expedition_ends_at"
    t.datetime "spirit_expedition_started_at"
    t.integer "sublevel", default: 1, null: false
    t.bigint "total_experience", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["daily_reward_claimed_at"], name: "index_characters_on_daily_reward_claimed_at"
    t.index ["name"], name: "index_characters_on_name", unique: true
    t.index ["sect_contribution"], name: "index_characters_on_sect_contribution"
    t.index ["sect_key"], name: "index_characters_on_sect_key"
    t.index ["sparring_available_at"], name: "index_characters_on_sparring_available_at"
    t.index ["spirit_expedition_ends_at"], name: "index_characters_on_spirit_expedition_ends_at"
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

  create_table "news_posts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "published_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["published_at"], name: "index_news_posts_on_published_at"
  end

  create_table "news_reads", force: :cascade do |t|
    t.integer "character_id", null: false
    t.datetime "created_at", null: false
    t.integer "news_post_id", null: false
    t.datetime "read_at", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id", "news_post_id"], name: "index_news_reads_on_character_id_and_news_post_id", unique: true
    t.index ["character_id"], name: "index_news_reads_on_character_id"
    t.index ["news_post_id"], name: "index_news_reads_on_news_post_id"
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

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "character_achievements", "characters"
  add_foreign_key "character_event_cooldowns", "characters"
  add_foreign_key "character_meridians", "characters"
  add_foreign_key "characters", "users"
  add_foreign_key "game_events", "characters"
  add_foreign_key "game_events", "characters", column: "related_character_id"
  add_foreign_key "inventory_items", "characters"
  add_foreign_key "news_reads", "characters"
  add_foreign_key "news_reads", "news_posts"
  add_foreign_key "sessions", "users"
end
