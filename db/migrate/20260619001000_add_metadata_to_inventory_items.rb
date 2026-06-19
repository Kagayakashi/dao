class AddMetadataToInventoryItems < ActiveRecord::Migration[8.1]
  def change
    add_column :inventory_items, :metadata, :text, null: false, default: "{}"
  end
end
