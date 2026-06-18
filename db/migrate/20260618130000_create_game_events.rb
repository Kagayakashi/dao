class CreateGameEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :game_events do |t|
      t.references :character, null: false, foreign_key: true
      t.references :related_character, foreign_key: { to_table: :characters }
      t.string :event_key, null: false
      t.string :outcome, null: false
      t.string :title, null: false
      t.text :description, null: false
      t.integer :qi_delta, null: false, default: 0
      t.datetime :happened_at, null: false

      t.timestamps
    end

    add_index :game_events, [ :character_id, :happened_at ]
  end
end
