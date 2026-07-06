class CreateCharacterMeridians < ActiveRecord::Migration[8.1]
  def change
    create_table :character_meridians do |t|
      t.references :character, null: false, foreign_key: true
      t.string :key, null: false
      t.integer :opened_subpoints, null: false, default: 0
      t.boolean :active, null: false, default: false

      t.timestamps
    end

    add_index :character_meridians, [ :character_id, :key ], unique: true
    add_index :character_meridians, [ :character_id, :active ]
  end
end
