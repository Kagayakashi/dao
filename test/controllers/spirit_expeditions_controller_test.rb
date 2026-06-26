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
    assert_select ".activity-option-card", text: /150-300 Wen/
    assert_select ".activity-option-card", text: /450-900 Wen/
    assert_select ".activity-option-card", text: /900-1,800 Wen/
    assert_select ".screen-note", text: /low chance to return with 1 Liang/
  end

  test "completes spirit expedition and creates event log" do
    user = users(:one)
    character = user.character
    now = Time.zone.local(2026, 6, 18, 12, 0, 0)
    character.start_spirit_expedition!(hours: 1, at: now)
    sign_in_as(user)

    travel_to(now + 1.hour) do
      assert_difference -> { character.game_events.count }, 1 do
        get spirit_expedition_path(locale: :en)
      end
    end

    event = character.game_events.order(:created_at).last
    assert_equal "spirit_expedition", event.event_key
    assert_equal 1, event.metadata.fetch("hours")
    assert_operator event.metadata.fetch("wen"), :>=, 50
    assert_operator event.metadata.fetch("wen"), :<=, 100
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
