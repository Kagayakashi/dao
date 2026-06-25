class CreateNewsReads < ActiveRecord::Migration[8.1]
  def change
    create_table :news_reads do |t|
      t.references :character, null: false, foreign_key: true
      t.references :news_post, null: false, foreign_key: true
      t.datetime :read_at, null: false

      t.timestamps
    end

    add_index :news_reads, [ :character_id, :news_post_id ], unique: true
  end
end
