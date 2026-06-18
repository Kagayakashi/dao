class CreateCharacterEventCooldowns < ActiveRecord::Migration[8.1]
  def change
    create_table :character_event_cooldowns do |t|
      t.references :character, null: false, foreign_key: true
      t.string :event_key, null: false
      t.datetime :next_event_at, null: false

      t.timestamps
    end

    add_index :character_event_cooldowns, [ :character_id, :event_key ], unique: true
  end
end
