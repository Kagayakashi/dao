require "test_helper"

class InventoriesControllerTest < ActionDispatch::IntegrationTest
  test "redirects guests to sign in" do
    get inventory_path(locale: :en)

    assert_redirected_to new_session_path(locale: :en)
  end

  test "shows current user inventory and equipment" do
    user = users(:one)
    character = user.character
    character.inventory_items.destroy_all
    item = character.create_inventory_item!(name: "iron_dao_blade", equipment_kind: "weapon", power_options: [ { "key" => "power", "value" => 10 } ])
    sign_in_as(user)

    get inventory_path(locale: :en)

    assert_response :success
    assert_select "h1", "Inventory"
    assert_select "#equipment-heading", "Equipment"
    assert_select "#inventory-heading", "Inventory"
    assert_select ".total-qi", text: /9 free slots/
    assert_select ".inventory-card", text: /Iron Dao Blade/
    assert_select "form[action='#{equip_inventory_item_path(item, locale: :en)}']"
  end
end
