require "test_helper"

class SparringControllerTest < ActionDispatch::IntegrationTest
  test "shows random opponent and spare button" do
    user = users(:one)
    user.character.update!(sparring_points: 3)
    sign_in_as(user)

    get sparring_path(locale: :en)

    assert_response :success
    assert_select ".main-banner img[alt='Sparring courtyard'][src*='sparring']"
    assert_select "h1", "Sparring"
    assert_select ".sparring-card", text: %r{3/3}
    assert_select "#sparring-opponent-heading", text: /Sparring Opponent/
    assert_select ".sparring-matchup"
    assert_select ".sparring-stat-table th", text: /DMG/
    assert_select ".sparring-stat-table th", text: /ACC/
    assert_select ".sparring-stat-table", text: /GearScore/, count: 0
    assert_select "form button", "Attack"
    assert_select "form button", "Change Cultivator"
  end

  test "blocks sparring actions during spirit expedition" do
    user = users(:one)
    character = user.character
    opponent = users(:two).character
    character.update!(sparring_points: 3)
    character.start_spirit_expedition!(hours: 4)
    sign_in_as(user)

    get sparring_path(locale: :en)

    assert_response :success
    assert_select ".form-alert", text: /Sparring is unavailable/
    assert_select "form button[disabled]", "Attack"
    assert_select "form button[disabled]", "Change Cultivator"

    assert_no_difference -> { character.game_events.count } do
      post sparring_path(locale: :en), params: { opponent_id: opponent.id }
    end
    follow_redirect!

    assert_equal 3, character.reload.sparring_points
    assert_select ".form-alert", text: /Return before attacking/
  end

  test "keeps same opponent when page is reopened" do
    third_user = User.create!(email_address: "silent-reed@example.com", password: "password", character_name: "Silent Reed")
    user = users(:one)
    sign_in_as(user)

    get sparring_path(locale: :en)
    first_opponent_name = opponent_name_from_response(third_user.character)

    get sparring_path(locale: :en)

    assert_includes response.body, first_opponent_name
  end

  test "changing opponent spends one sparring point" do
    User.create!(email_address: "mist-pine@example.com", password: "password", character_name: "Mist Pine")
    user = users(:one)
    character = user.character
    character.update!(sparring_points: 3, sparring_recovered_at: Time.current)
    sign_in_as(user)

    post change_opponent_sparring_path(locale: :en)
    follow_redirect!

    assert_equal 2, character.reload.sparring_points
    assert_select ".form-notice", text: /Another cultivator/
  end

  test "spare resolves immediately and spends one point" do
    user = users(:one)
    character = user.character
    opponent = users(:two).character
    character.update!(realm: 2, star: 1, qi: 0, total_experience: 0, sparring_points: 3, sparring_recovered_at: 1.hour.ago)
    opponent.update!(realm: 1, star: 1)
    sign_in_as(user)

    assert_difference -> { character.game_events.count }, 1 do
      assert_difference -> { opponent.game_events.count }, 1 do
        post sparring_path(locale: :en), params: { opponent_id: opponent.id }
      end
    end

    assert_redirected_to %r{/en/sparring\?result_event_id=\d+}
    character.reload
    assert_equal 2, character.sparring_points
    assert_includes [ 0, 3_600 ], character.qi
    assert_operator opponent.reload.current_health, :<, opponent.health
    event = character.game_events.order(:created_at).last
    assert_includes %w[victory defeat], event.outcome
    assert event.metadata.key?("damage_done")
    assert event.metadata.key?("health_remaining")

    get sparring_path(locale: :en, result_event_id: event.id)

    assert_response :success
    assert_select ".event-notice", text: /Your chance:/, count: 0
  end

  test "sparring regenerates opponent health before combat" do
    user = users(:one)
    character = user.character
    opponent = users(:two).character
    opponent.update!(realm: 1, star: 1)
    character.update!(sparring_points: 3, sparring_recovered_at: Time.current)
    recovered_from = 10.minutes.ago
    opponent.update!(current_health: (opponent.health * 25 / 100) + 1, health_recovered_at: recovered_from)
    sign_in_as(user)

    post sparring_path(locale: :en), params: { opponent_id: opponent.id }

    assert_operator opponent.reload.health_recovered_at, :>, recovered_from
  end

  test "does not show opponent with low health" do
    user = users(:one)
    opponent = users(:two).character
    opponent.update!(current_health: 1, health_recovered_at: Time.current)
    sign_in_as(user)

    get sparring_path(locale: :en)

    assert_response :success
    assert_select "#sparring-opponent-heading"
    assert_select "form button", "Attack"

    post sparring_path(locale: :en), params: { opponent_id: opponent.id }
    follow_redirect!

    assert_select ".form-alert", text: /too injured/
  end

  test "does not resolve without sparring focus" do
    user = users(:one)
    character = user.character
    opponent = users(:two).character
    character.update!(sparring_points: 0, sparring_recovered_at: Time.current)
    sign_in_as(user)

    assert_no_difference -> { character.game_events.count } do
      post sparring_path(locale: :en), params: { opponent_id: opponent.id }
    end

    assert_redirected_to sparring_path(locale: :en)
    follow_redirect!
    assert_select ".form-alert", text: /Rest before attacking again/
  end

  test "changing opponent without sparring focus does not spend or change" do
    third_user = User.create!(email_address: "still-lake@example.com", password: "password", character_name: "Still Lake")
    user = users(:one)
    character = user.character
    character.update!(sparring_points: 0, sparring_recovered_at: Time.current)
    sign_in_as(user)

    get sparring_path(locale: :en)
    first_opponent_name = opponent_name_from_response(third_user.character)

    post change_opponent_sparring_path(locale: :en)
    follow_redirect!

    assert_equal 0, character.reload.sparring_points
    assert_select ".form-alert", text: /Rest before changing partners/
    assert_includes response.body, first_opponent_name
  end

  private

  def opponent_name_from_response(extra_character)
    return "Quiet Flame" if response.body.include?("Quiet Flame")
    return extra_character.name if response.body.include?(extra_character.name)

    flunk "Expected response to include a sparring opponent"
  end
end
