require "test_helper"

class InventoryItemTest < ActiveSupport::TestCase
  setup do
    @character = characters(:one)
    @character.inventory_items.destroy_all
  end

  test "creates item in first free inventory slot" do
    item = @character.create_inventory_item!(name: "cloud_ring", equipment_kind: "ring", power_options: [ { "key" => "power", "value" => 20 }, { "key" => "health", "value" => 15 } ])

    assert_equal 1, item.inventory_slot
    assert_nil item.equipment_slot
    assert_equal 20, item.inventory_power
  end

  test "localizes generated item name from stored key" do
    item = @character.create_inventory_item!(
      name: "iron_dao_blade",
      equipment_kind: "weapon",
      power_options: []
    )

    I18n.with_locale(:en) do
      assert_equal "Iron Dao Blade", item.localized_name
    end

    I18n.with_locale(:ru) do
      assert_equal "Железный клинок Дао", item.localized_name
    end
  end

  test "localizes generated stat option names" do
    item = @character.create_inventory_item!(name: "cloud_ring", equipment_kind: "ring", power_options: [ { "key" => "power", "value" => 20 }, { "key" => "health", "value" => 15 } ])

    I18n.with_locale(:ru) do
      assert_equal [ { "key" => "power", "value" => 20, "name" => "Сила" }, { "key" => "health", "value" => 15, "name" => "Здоровье" } ], item.localized_power_options
    end
  end

  test "fills up to ten inventory slots" do
    10.times do |index|
      assert @character.create_inventory_item!(name: "iron_dao_blade", equipment_kind: "weapon", power_options: [], metadata: { "test_slot" => index })
    end

    assert_predicate @character, :inventory_full?
    assert_not @character.create_inventory_item!(name: "ashen_spear", equipment_kind: "weapon", power_options: [])
  end

  test "equips item and frees inventory slot" do
    item = @character.create_inventory_item!(name: "iron_dao_blade", equipment_kind: "weapon", power_options: [ { "key" => "power", "value" => 40 } ])

    assert @character.equip_item!(item)

    item.reload
    assert_nil item.inventory_slot
    assert_equal "weapon", item.equipment_slot
    assert_equal 40, @character.equipment_power
  end

  test "equips rings into two ring slots" do
    first = @character.create_inventory_item!(name: "cloud_ring", equipment_kind: "ring", power_options: [])
    second = @character.create_inventory_item!(name: "jade_band", equipment_kind: "ring", power_options: [])

    assert @character.equip_item!(first)
    assert @character.equip_item!(second)

    assert_equal %w[ ring_one ring_two ], @character.inventory_items.equipped.order(:equipment_slot).pluck(:equipment_slot)
  end

  test "does not unequip when inventory is full" do
    item = @character.create_inventory_item!(name: "old_dragon_pendant", equipment_kind: "pendant", power_options: [])
    @character.equip_item!(item)
    10.times { |index| @character.create_inventory_item!(name: "iron_dao_blade", equipment_kind: "weapon", power_options: [], metadata: { "test_slot" => index }) }

    assert_not @character.unequip_item!(item.reload)
    assert_equal "pendant", item.reload.equipment_slot
  end

  test "unequips into free inventory slot" do
    item = @character.create_inventory_item!(name: "old_dragon_pendant", equipment_kind: "pendant", power_options: [])
    @character.equip_item!(item)

    assert @character.unequip_item!(item.reload)

    item.reload
    assert_nil item.equipment_slot
    assert_equal 1, item.inventory_slot
  end
end
