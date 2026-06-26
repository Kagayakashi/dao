require "test_helper"

class EventsControllerTest < ActionDispatch::IntegrationTest
  test "redirects guests to sign in" do
    get events_path(locale: :en)

    assert_redirected_to new_session_path(locale: :en)
  end

  test "shows ten events per page with pagination" do
    user = users(:one)
    character = user.character
    character.game_events.destroy_all
    12.times do |index|
      character.game_events.create!(
        event_key: "test_event_#{index}",
        outcome: "neutral",
        title: "Event #{index + 1}",
        description: "Description #{index + 1}",
        metadata: {},
        qi_delta: index.zero? ? 100 : 0,
        happened_at: index.minutes.ago
      )
    end
    sign_in_as(user)

    get events_path(locale: :en)

    assert_response :success
    assert_select "h1", "Event Log"
    assert_select ".event-list li", 10
    assert_select ".event-list", text: /Event 1/
    assert_select ".event-list", text: /\+100 Qi/
    assert_select ".event-list", { text: /Event 11/, count: 0 }
    assert_select "a", "Next"
    assert_includes response.body, events_path(locale: :en, page: 2)
    assert_select "a", { text: "Previous", count: 0 }

    get events_path(locale: :en, page: 2)

    assert_response :success
    assert_select ".event-list li", 2
    assert_select ".event-list", text: /Event 11/
    assert_select "a", "Previous"
    assert_includes response.body, events_path(locale: :en, page: 1)
    assert_select "a", { text: "Next", count: 0 }
  end

  test "shows empty event log" do
    user = users(:one)
    user.character.game_events.destroy_all
    sign_in_as(user)

    get events_path(locale: :en)

    assert_response :success
    assert_select ".empty-state", text: /No events/
  end
end
