require "test_helper"

class ShopsControllerTest < ActionDispatch::IntegrationTest
  test "redirects guests to sign in" do
    get shop_path(locale: :en)

    assert_redirected_to new_session_path(locale: :en)
  end

  test "shows shop" do
    user = users(:one)
    user.character.update!(currency: 300)
    user.character.inventory_items.destroy_all
    user.character.create_inventory_item!(name: "iron_dao_blade", equipment_kind: "weapon", power_options: [ { "key" => "power", "value" => 1 } ])
    sign_in_as(user)

    get shop_path(locale: :en)

    assert_response :success
    assert_select "h1", "Shop"
    assert_select ".realm-card", text: /300 Wen/
    assert_select "form button", "Buy Random Item"
    assert_select "h2", "Sell Inventory Items"
    assert_select ".action-card", text: /Iron Dao Blade/
    assert_select "form button", "Sell for 150 Wen"
  end

  test "buying item spends wen and creates random item" do
    user = users(:one)
    character = user.character
    character.update!(currency: 300)
    sign_in_as(user)

    assert_difference -> { character.inventory_items.count }, 1 do
      assert_difference -> { character.game_events.count }, 1 do
        post shop_path(locale: :en)
      end
    end

    assert_redirected_to shop_path(locale: :en)
    assert_equal 0, character.reload.currency
    item = character.inventory_items.order(:created_at).last
    assert_includes InventoryItem::EQUIPMENT_KINDS, item.equipment_kind
    assert item.power_options.present?
    assert_equal "shop_purchase", character.game_events.order(:created_at).last.event_key
  end

  test "does not buy without enough wen" do
    user = users(:one)
    character = user.character
    character.update!(currency: 299)
    sign_in_as(user)

    assert_no_difference -> { character.inventory_items.count } do
      post shop_path(locale: :en)
    end
    follow_redirect!

    assert_equal 299, character.reload.currency
    assert_select ".form-alert", text: /Bring 300 Wen/
  end

  test "does not buy when inventory is full" do
    user = users(:one)
    character = user.character
    character.inventory_items.destroy_all
    Character::INVENTORY_SLOTS.times do
      character.create_inventory_item!(name: "iron_dao_blade", equipment_kind: "weapon", power_options: [ { "key" => "power", "value" => 1 } ])
    end
    character.update!(currency: 300)
    sign_in_as(user)

    assert_no_difference -> { character.inventory_items.count } do
      post shop_path(locale: :en)
    end
    follow_redirect!

    assert_equal 300, character.reload.currency
    assert_select ".form-alert", text: /inventory is full/
  end

  test "blocks shop during spirit expedition" do
    user = users(:one)
    character = user.character
    character.update!(currency: 300)
    character.start_spirit_expedition!(hours: 4)
    sign_in_as(user)

    get shop_path(locale: :en)

    assert_response :success
    assert_select ".form-alert", text: /Shopping is unavailable/
    assert_select "form button[disabled]", "Buy Random Item"

    assert_no_difference -> { character.inventory_items.count } do
      post shop_path(locale: :en)
    end
    follow_redirect!

    assert_equal 300, character.reload.currency
    assert_select ".form-alert", text: /Return before buying items/
  end

  test "sells inventory item for wen" do
    user = users(:one)
    character = user.character
    character.update!(currency: 10)
    character.inventory_items.destroy_all
    item = character.create_inventory_item!(name: "iron_dao_blade", equipment_kind: "weapon", power_options: [ { "key" => "power", "value" => 1 } ])
    sign_in_as(user)

    assert_difference -> { character.inventory_items.count }, -1 do
      assert_difference -> { character.game_events.count }, 1 do
        post sell_shop_path(locale: :en), params: { inventory_item_id: item.id }
      end
    end

    assert_redirected_to shop_path(locale: :en)
    assert_equal 160, character.reload.currency
    assert_equal "shop_sale", character.game_events.order(:created_at).last.event_key
  end

  test "does not sell equipped item" do
    user = users(:one)
    character = user.character
    character.update!(currency: 10)
    character.inventory_items.destroy_all
    item = character.create_inventory_item!(name: "iron_dao_blade", equipment_kind: "weapon", power_options: [ { "key" => "power", "value" => 1 } ])
    character.equip_item!(item)
    sign_in_as(user)

    assert_no_difference -> { character.inventory_items.count } do
      post sell_shop_path(locale: :en), params: { inventory_item_id: item.id }
    end
    follow_redirect!

    assert_equal 10, character.reload.currency
    assert_select ".form-alert", text: /Equipped items cannot be sold/
  end
end
