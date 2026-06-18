require "test_helper"

class InventoryItemTest < ActiveSupport::TestCase
  setup do
    @character = characters(:one)
    @character.inventory_items.destroy_all
  end

  test "creates item in first free inventory slot" do
    item = @character.create_inventory_item!(name: "Cloud Ring", equipment_kind: "ring", power_options: [ { "name" => "Power", "value" => 20 } ])

    assert_equal 1, item.inventory_slot
    assert_nil item.equipment_slot
    assert_equal 20, item.inventory_power
  end

  test "fills up to ten inventory slots" do
    10.times do |index|
      assert @character.create_inventory_item!(name: "Item #{index}", equipment_kind: "weapon", power_options: [])
    end

    assert_predicate @character, :inventory_full?
    assert_not @character.create_inventory_item!(name: "Extra", equipment_kind: "weapon", power_options: [])
  end

  test "equips item and frees inventory slot" do
    item = @character.create_inventory_item!(name: "Iron Dao Blade", equipment_kind: "weapon", power_options: [ { "name" => "Power", "value" => 40 } ])

    assert @character.equip_item!(item)

    item.reload
    assert_nil item.inventory_slot
    assert_equal "weapon", item.equipment_slot
    assert_equal 40, @character.equipment_power
  end

  test "equips rings into two ring slots" do
    first = @character.create_inventory_item!(name: "Cloud Ring", equipment_kind: "ring", power_options: [])
    second = @character.create_inventory_item!(name: "Jade Band", equipment_kind: "ring", power_options: [])

    assert @character.equip_item!(first)
    assert @character.equip_item!(second)

    assert_equal %w[ ring_one ring_two ], @character.inventory_items.equipped.order(:equipment_slot).pluck(:equipment_slot)
  end

  test "does not unequip when inventory is full" do
    item = @character.create_inventory_item!(name: "Old Dragon Pendant", equipment_kind: "pendant", power_options: [])
    @character.equip_item!(item)
    10.times { |index| @character.create_inventory_item!(name: "Stored #{index}", equipment_kind: "weapon", power_options: []) }

    assert_not @character.unequip_item!(item.reload)
    assert_equal "pendant", item.reload.equipment_slot
  end

  test "unequips into free inventory slot" do
    item = @character.create_inventory_item!(name: "Old Dragon Pendant", equipment_kind: "pendant", power_options: [])
    @character.equip_item!(item)

    assert @character.unequip_item!(item.reload)

    item.reload
    assert_nil item.equipment_slot
    assert_equal 1, item.inventory_slot
  end
end
