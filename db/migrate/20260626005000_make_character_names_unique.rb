class MakeCharacterNamesUnique < ActiveRecord::Migration[8.1]
  class MigrationCharacter < ActiveRecord::Base
    self.table_name = "characters"
  end

  def up
    rename_duplicate_character_names
    add_index :characters, :name, unique: true
  end

  def down
    remove_index :characters, :name
  end

  private

  def rename_duplicate_character_names
    duplicate_names.each do |name|
      MigrationCharacter.where(name:).order(:id).offset(1).each do |character|
        character.update_columns(name: random_character_name)
      end
    end
  end

  def duplicate_names
    MigrationCharacter.group(:name).having("COUNT(*) > 1").pluck(:name)
  end

  def random_character_name
    loop do
      name = "Wandering Cultivator #{SecureRandom.alphanumeric(6)}"
      break name unless MigrationCharacter.exists?(name:)
    end
  end
end
