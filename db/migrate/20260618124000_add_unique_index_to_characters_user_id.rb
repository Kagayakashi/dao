class AddUniqueIndexToCharactersUserId < ActiveRecord::Migration[8.1]
  def change
    remove_index :characters, :user_id
    add_index :characters, :user_id, unique: true
  end
end
