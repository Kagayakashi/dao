class AddSpiritExpeditionToCharacters < ActiveRecord::Migration[8.1]
  def change
    add_column :characters, :spirit_expedition_started_at, :datetime
    add_column :characters, :spirit_expedition_ends_at, :datetime
    add_column :characters, :spirit_expedition_duration_hours, :integer

    add_index :characters, :spirit_expedition_ends_at
  end
end
