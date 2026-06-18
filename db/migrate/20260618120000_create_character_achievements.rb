class CreateCharacterAchievements < ActiveRecord::Migration[8.1]
  def change
    create_table :character_achievements do |t|
      t.references :character, null: false, foreign_key: true
      t.string :key, null: false
      t.datetime :earned_at, null: false

      t.timestamps
    end

    add_index :character_achievements, [ :character_id, :key ], unique: true
  end
end
