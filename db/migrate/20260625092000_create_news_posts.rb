class CreateNewsPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :news_posts do |t|
      t.string :title, null: false
      t.datetime :published_at, null: false

      t.timestamps
    end

    add_index :news_posts, :published_at
  end
end
