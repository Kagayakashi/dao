class AddNameToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :name, :string, null: false, default: "Wandering Cultivator"
  end
end
