class AddGenderToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :gender, :string, null: false, default: "male"
  end
end
