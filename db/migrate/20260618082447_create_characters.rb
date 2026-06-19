class CreateCharacters < ActiveRecord::Migration[8.1]
  def change
    create_table :characters do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :name, null: false, default: "Wandering Cultivator"
      t.string :gender, null: false, default: "male"

      t.integer :reset, null: false, default: 0

      t.integer :level, null: false, default: 1
      t.integer :sublevel, null: false, default: 1
      t.bigint  :experience, null: false, default: 0

      t.bigint  :total_experience, null: false, default: 0

      t.bigint :currency, null: false, default: 0

      t.datetime :last_online, default: -> { 'CURRENT_TIMESTAMP' }

      t.timestamps
    end

    add_index :characters, :user_id, unique: true
  end
end
