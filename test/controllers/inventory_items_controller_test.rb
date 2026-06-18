require "test_helper"

class InventoryItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @character = @user.character
    @character.inventory_items.destroy_all
    sign_in_as(@user)
  end

  test "equips inventory item" do
    item = @character.create_inventory_item!(name: "Iron Dao Blade", equipment_kind: "weapon", power_options: [])

    post equip_inventory_item_path(id: item, locale: :en)

    assert_redirected_to root_path(locale: :en)
    assert_equal "weapon", item.reload.equipment_slot
  end

  test "unequips equipment item" do
    item = @character.create_inventory_item!(name: "Iron Dao Blade", equipment_kind: "weapon", power_options: [])
    @character.equip_item!(item)

    post unequip_inventory_item_path(id: item, locale: :en)

    assert_redirected_to root_path(locale: :en)
    assert_equal 1, item.reload.inventory_slot
  end

  test "drops item" do
    item = @character.create_inventory_item!(name: "Iron Dao Blade", equipment_kind: "weapon", power_options: [])

    assert_difference -> { @character.inventory_items.count }, -1 do
      delete inventory_item_path(id: item, locale: :en)
    end

    assert_redirected_to root_path(locale: :en)
  end
end
