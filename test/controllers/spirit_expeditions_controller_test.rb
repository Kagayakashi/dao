require "test_helper"

class SpiritExpeditionsControllerTest < ActionDispatch::IntegrationTest
  test "shows spirit expedition options" do
    sign_in_as(users(:one))

    get spirit_expedition_path(locale: :en)

    assert_response :success
    assert_select "h1", "Spirit Expedition"
    assert_select "form[action='#{spirit_expedition_path(locale: :en)}']", 4
    assert_select ".activity-option-card", text: /1h/
    assert_select ".activity-option-card", text: /4h/
    assert_select ".activity-option-card", text: /3,600 Qi/
    assert_select ".activity-option-card", text: /50-100 Wen/
  end

  test "starts spirit expedition" do
    user = users(:one)
    sign_in_as(user)

    post spirit_expedition_path(locale: :en), params: { hours: 4 }

    assert_redirected_to spirit_expedition_path(locale: :en)
    character = user.character.reload
    assert_equal 4, character.spirit_expedition_duration_hours
    assert_predicate character, :spirit_expedition_active?
  end

  test "shows active spirit expedition instead of start options" do
    user = users(:one)
    user.character.start_spirit_expedition!(hours: 4)
    sign_in_as(user)

    get spirit_expedition_path(locale: :en)

    assert_response :success
    assert_select ".realm-card", text: /Expedition underway/
    assert_select "form[action='#{spirit_expedition_path(locale: :en)}']", 0
  end
end
