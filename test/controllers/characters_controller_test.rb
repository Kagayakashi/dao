require "test_helper"

class CharactersControllerTest < ActionDispatch::IntegrationTest
  test "redirects guests to sign in" do
    get character_path(characters(:one), locale: :en)

    assert_redirected_to new_session_path(locale: :en)
  end

  test "shows any character profile" do
    users(:two).character.character_achievements.create!(key: "first_star", earned_at: Time.current)
    users(:two).character.create_inventory_item!(name: "iron_dao_blade", equipment_kind: "weapon", power_options: [ { "key" => "power", "value" => 10 } ])
    users(:two).character.equip_item!(users(:two).character.inventory_items.first)
    sign_in_as(users(:one))

    get character_path(users(:two).character, locale: :en)

    assert_response :success
    assert_select ".profile-banner"
    assert_select ".profile-banner img[alt='Male cultivator profile image'][src*='male_profile']"
    assert_select "h1", "Quiet Flame"
    assert_select ".realm-card", text: /Dou Qi Stage/
    assert_select ".realm-card", text: /1 Star/
    assert_select ".realm-card", text: /Gender: Male/
    assert_select ".realm-card", text: /Gear Score:/
    assert_select "#profile-combat-stats-heading", "Combat Stats"
    assert_select ".combat-stat-list", text: /Damage/
    assert_select ".combat-stat-list", text: /Health/
    assert_select ".combat-stat-list", text: /Defense/
    assert_select ".combat-stat-list", text: /Evasion/
    assert_select ".combat-stat-list", text: /Accuracy/
    assert_select ".combat-stat-list", text: /Critical Rate/
    assert_select ".achievements", text: /First Star/
    assert_select "#profile-equipment-heading", "Equipment"
    assert_select ".inventory-card", text: /Iron Dao Blade/
    assert_select "a", text: /Inventory/, count: 0
  end

  test "shows attack button on other player's profile" do
    users(:one).character.update!(sparring_points: 3)
    sign_in_as(users(:one))

    get character_path(users(:two).character, locale: :en)

    assert_response :success
    assert_select ".profile-actions form[action*='opponent_id'] button", "Attack"
    assert_select ".profile-actions form[action*='opponent_id'] button[disabled]", count: 0
  end

  test "disables attack button on profile without sparring focus" do
    users(:one).character.update!(sparring_points: 0, sparring_recovered_at: Time.current)
    sign_in_as(users(:one))

    get character_path(users(:two).character, locale: :en)

    assert_response :success
    assert_select ".profile-actions form[action*='opponent_id'] button[disabled]", "Attack"
  end

  test "disables attack button on profile with low health" do
    character = users(:one).character
    character.update!(sparring_points: 3, current_health: character.health * 25 / 100, health_recovered_at: Time.current)
    sign_in_as(users(:one))

    get character_path(users(:two).character, locale: :en)

    assert_response :success
    assert_select ".profile-actions form[action*='opponent_id'] button[disabled]", "Attack"
  end

  test "does not show attack button on own profile" do
    sign_in_as(users(:one))

    get character_path(users(:one).character, locale: :en)

    assert_response :success
    assert_select "form button", text: "Attack", count: 0
  end

  test "shows inventory link on own profile" do
    sign_in_as(users(:one))

    get character_path(users(:one).character, locale: :en)

    assert_response :success
    assert_select "a[href='#{inventory_path(locale: :en)}']", "Inventory"
  end

  test "shows complete registration link on own temporary profile" do
    users(:one).update!(temporary: true)
    sign_in_as(users(:one))

    get character_path(users(:one).character, locale: :en)

    assert_response :success
    assert_select "a[href='#{new_registration_completion_path(locale: :en)}']", "Set Email and Password"
  end
end
