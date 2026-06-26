class RerollExistingInventoryItemPowerOptions2 < ActiveRecord::Migration[8.1]
  def up
    say_with_time "Rerolling existing inventory item Power options 2" do
      InventoryItem.includes(:character).find_each do |item|
        item.update!(power_options: InventoryItems::PowerRoll.new(item.character, equipment_kind: item.equipment_kind).call)
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Previous item Power rolls cannot be restored"
  end
end
