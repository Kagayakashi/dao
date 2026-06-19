class AddMetadataToGameEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :game_events, :metadata, :text, null: false, default: "{}"
  end
end
