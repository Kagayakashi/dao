require "test_helper"

class ArtifactRefinementsControllerTest < ActionDispatch::IntegrationTest
  test "redirects guests to sign in" do
    get artifact_refinement_path(locale: :en)

    assert_redirected_to new_session_path(locale: :en)
  end

  test "shows inventory and equipped items" do
    user = users(:one)
    character = user.character
    inventory_item = character.create_inventory_item!(name: "iron_dao_blade", equipment_kind: "weapon", power_options: [ { "key" => "power", "value" => 10 } ])
    equipped_item = character.create_inventory_item!(name: "cloud_ring", equipment_kind: "ring", power_options: [ { "key" => "power", "value" => 20 } ])
    character.equip_item!(equipped_item)
    sign_in_as(user)

    get artifact_refinement_path(locale: :en)

    assert_response :success
    assert_select "h1", "Artifact Refinement Hall"
    assert_select ".inventory-card", text: /#{inventory_item.localized_name}/
    assert_select ".inventory-card", text: /Inventory Slot 1/
    assert_select ".inventory-card", text: /#{equipped_item.localized_name}/
    assert_select ".inventory-card", text: /Equipped: Ring I/
    assert_select "form button", "Refine for 300 Wen"
    assert_select "form button", "Refine for 1 Liang"
  end

  test "rerolls item power with wen" do
    user = users(:one)
    character = user.character
    item = character.create_inventory_item!(name: "iron_dao_blade", equipment_kind: "weapon", power_options: [ { "key" => "power", "value" => 1 } ])
    character.update!(currency: 300, donation_currency: 0)
    sign_in_as(user)

    assert_difference -> { character.game_events.count }, 1 do
      post reroll_artifact_refinement_path(locale: :en), params: { item_id: item.id, payment: "wen" }
    end

    assert_redirected_to artifact_refinement_path(locale: :en)
    character.reload
    assert_equal 0, character.currency
    assert_equal 0, character.donation_currency
    assert_not_equal [ { "key" => "power", "value" => 1 } ], item.reload.power_options
    assert_equal "artifact_refinement", character.game_events.order(:created_at).last.event_key
  end

  test "rerolls item power with liang" do
    user = users(:one)
    character = user.character
    item = character.create_inventory_item!(name: "cloud_ring", equipment_kind: "ring", power_options: [ { "key" => "power", "value" => 1 } ])
    character.update!(currency: 0, donation_currency: 1)
    sign_in_as(user)

    post reroll_artifact_refinement_path(locale: :en), params: { item_id: item.id, payment: "liang" }

    assert_redirected_to artifact_refinement_path(locale: :en)
    character.reload
    assert_equal 0, character.currency
    assert_equal 0, character.donation_currency
    assert_not_equal [ { "key" => "power", "value" => 1 } ], item.reload.power_options
  end

  test "does not reroll without enough currency" do
    user = users(:one)
    character = user.character
    item = character.create_inventory_item!(name: "old_dragon_pendant", equipment_kind: "pendant", power_options: [ { "key" => "power", "value" => 12 } ])
    character.update!(currency: 299, donation_currency: 0)
    sign_in_as(user)

    assert_no_difference -> { character.game_events.count } do
      post reroll_artifact_refinement_path(locale: :en), params: { item_id: item.id, payment: "wen" }
    end
    follow_redirect!

    assert_equal 299, character.reload.currency
    assert_equal [ { "key" => "power", "value" => 12 } ], item.reload.power_options
    assert_select ".form-alert", text: /Bring 300 Wen/
  end
end
