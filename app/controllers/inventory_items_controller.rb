class InventoryItemsController < ApplicationController
  before_action :set_inventory_item

  def equip
    Current.user.character.equip_item!(@inventory_item, preferred_slot: params[:equipment_slot])
    redirect_to inventory_path, status: :see_other
  end

  def unequip
    Current.user.character.unequip_item!(@inventory_item)
    redirect_to inventory_path, status: :see_other
  end

  def destroy
    @inventory_item.destroy!
    redirect_to inventory_path, status: :see_other
  end

  private

  def set_inventory_item
    @inventory_item = Current.user.character.inventory_items.find(params[:id])
  end
end
