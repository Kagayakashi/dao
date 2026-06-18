class CreateInventoryItems < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_items do |t|
      t.references :character, null: false, foreign_key: true
      t.string :name, null: false
      t.string :item_type, null: false, default: "equipment"
      t.string :equipment_kind, null: false
      t.integer :inventory_slot
      t.string :equipment_slot
      t.text :power_options, null: false, default: "[]"

      t.timestamps
    end

    add_index :inventory_items, [ :character_id, :inventory_slot ], unique: true, where: "inventory_slot IS NOT NULL"
    add_index :inventory_items, [ :character_id, :equipment_slot ], unique: true, where: "equipment_slot IS NOT NULL"
  end
end
