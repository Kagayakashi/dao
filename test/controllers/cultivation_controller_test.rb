require "test_helper"

class CultivationControllerTest < ActionDispatch::IntegrationTest
  setup do
    users(:one).character.character_event_cooldowns.destroy_all

    CultivationEvents::Registry.events.each_key do |event_key|
      users(:one).character.character_event_cooldowns.create!(event_key: event_key.to_s, next_event_at: 1.hour.from_now)
    end
  end

  test "redirects guests to sign in" do
    get root_path(locale: :en)

    assert_redirected_to new_session_path(locale: :en)
  end

  test "shows character cultivation dashboard" do
    user = users(:one)
    character = user.character || user.create_character!
    character.update!(realm: 2, star: 3, qi: 40, total_experience: 240, last_online: Time.current)
    sign_in_as(user)

    get root_path(locale: :en)

    assert_response :success
    assert_select "turbo-frame#cultivation_panel[data-controller='auto-refresh']"
    assert_select "h1", "Jade River"
    assert_select ".realm-card", text: /Dou Practitioner/
    assert_select ".realm-card", text: /3 Star/
    assert_select ".realm-card", text: /Power/
    assert_select ".qi-progress__text", text: /Qi/
    assert_select ".screen-note", text: /Qi gathers/
    assert_select ".next-breakthrough", text: /Next breakthrough/
    assert_select "#equipment-heading", "Equipment"
    assert_select "#inventory-heading", "Inventory"
  end

  test "shows earned achievements on dashboard" do
    user = users(:one)
    character = user.character || user.create_character!
    character.character_achievements.create!(key: "first_star", earned_at: Time.current)
    sign_in_as(user)

    get root_path(locale: :en)

    assert_response :success
    assert_select ".achievements", text: /First Star/
  end

  test "shows refreshable cultivation panel" do
    user = users(:one)
    sign_in_as(user)

    get cultivation_panel_path(locale: :en)

    assert_response :success
    assert_select "h1", "Jade River"
    assert_select ".quiet-nav", text: /Leaderboard/
    assert_select ".quiet-nav", text: /Sign out/
  end

  test "shows breakthrough button when enough qi is gathered" do
    user = users(:one)
    character = user.character
    character.update!(qi: character.qi_required_for_next_star, last_online: Time.current)
    sign_in_as(user)

    get root_path(locale: :en)

    assert_response :success
    assert_select ".breakthrough-ready", text: /breakthrough is ready/
    assert_select "form button", "Breakthrough"
  end

  test "breakthrough advances character manually" do
    user = users(:one)
    character = user.character
    required_qi = character.qi_required_for_next_star
    character.update!(realm: 1, star: 1, qi: required_qi, total_experience: required_qi, last_online: Time.current)
    sign_in_as(user)

    post cultivation_breakthrough_path(locale: :en)

    assert_redirected_to root_path(locale: :en)
    character.reload
    assert_equal 1, character.realm
    assert_equal 2, character.star
    assert_equal 0, character.qi
  end

  test "breakthrough shows qi loss notice when overflow is unstable" do
    user = users(:one)
    character = user.character
    required_qi = character.qi_required_for_next_star
    character.update!(realm: 1, star: 1, qi: required_qi + 900, total_experience: required_qi + 900, last_online: Time.current)
    sign_in_as(user)

    original_loss_range = Character.breakthrough_overflow_loss_range
    begin
      Character.breakthrough_overflow_loss_range = 10..10
      post cultivation_breakthrough_path(locale: :en)
    ensure
      Character.breakthrough_overflow_loss_range = original_loss_range
    end

    follow_redirect!

    assert_select ".form-notice", text: /unstable Qi dispersed/
    assert_operator character.reload.qi, :<, 900
  end

  test "applies offline cultivation when dashboard is visited" do
    user = users(:one)
    character = user.character || user.create_character!
    character.update!(qi: 0, total_experience: 0, last_online: 2.minutes.ago)
    sign_in_as(user)

    assert_changes -> { character.reload.total_experience } do
      get root_path(locale: :en)
    end

    assert_response :success
  end
end
