class AddSparringAvailableAtToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :sparring_available_at, :datetime
    add_index :characters, :sparring_available_at
  end
end
