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
    character.update!(realm: 2, star: 3, qi: 40, total_experience: 240, currency: 12, donation_currency: 5, last_online: Time.current, sparring_points: 2, sparring_recovered_at: 30.minutes.ago)
    sign_in_as(user)

    get root_path(locale: :en)

    assert_response :success
    assert_select "turbo-frame#cultivation_panel[data-controller='auto-refresh']"
    assert_select ".main-banner img[alt='Cultivation landscape'][src*='main']"
    assert_select ".global-header"
    assert_select ".global-header a[href='#{character_path(character, locale: :en)}']", text: /Jade River/
    assert_select ".global-header a[href='#{character_path(character, locale: :en)}']", text: /2/
    assert_select ".global-header a[href='#{character_path(character, locale: :en)}']", text: /3/
    assert_select ".global-header a[href='#{inventory_path(locale: :en)}']", text: /#{character.power}/
    assert_select ".global-header a[href='#{spirit_expedition_path(locale: :en)}'][title='Wen']", text: /12/
    assert_select ".global-header a[href='#{spirit_expedition_path(locale: :en)}'][title='Liang']", text: /5/
    assert_select ".global-header a[href='#{sparring_path(locale: :en)}']", text: %r{2/3}
    assert_select ".global-header a[href='#{sparring_path(locale: :en)}']", text: /\d{2}:\d{2}/
    assert_select "h1", "Jade River"
    assert_select ".realm-card", text: /Dou Practitioner/
    assert_select ".realm-card", text: /3 Star/
    assert_select ".realm-card", text: /Power/
    assert_select ".qi-progress__text", text: /Qi/
    assert_select ".screen-note", text: /Qi gathers/
    assert_select ".next-breakthrough", text: /Next breakthrough/
    assert_select ".sparring-card", text: %r{2/3}
    assert_select ".daily-reward-card", text: /1,350 Qi/
    assert_select ".daily-reward-card a[href='#{temple_path(locale: :en)}']", "Temple of Heaven"
    assert_select ".quiet-nav", text: /Profile/
    assert_select ".global-footer a[href='#{root_path(locale: :en)}']", "Home"
    assert_select ".global-footer a[href='#{leaderboard_path(locale: :en)}']", "Leaderboard"
    assert_select ".global-footer form button", "Sign out"
    assert_select "#equipment-heading", false
    assert_select "#inventory-heading", false
  end

  test "shows complete registration notice for temporary user" do
    user = users(:one)
    user.update!(temporary: true)
    sign_in_as(user)

    get root_path(locale: :en)

    assert_response :success
    assert_select ".offline-gain", text: /Complete registration/
    assert_select ".offline-gain", text: /1,000 bonus Qi/
    assert_select ".offline-gain a[href='#{new_registration_completion_path(locale: :en)}'][data-turbo-frame='_top']", text: /Complete registration/
  end

  test "hides daily reward card on dashboard after prayer" do
    user = users(:one)
    user.character.update!(daily_reward_claimed_at: Time.current)
    sign_in_as(user)

    get root_path(locale: :en)

    assert_response :success
    assert_select ".daily-reward-card", false
  end

  test "pauses passive cultivation while spirit expedition is active" do
    user = users(:one)
    character = user.character
    now = Time.current
    character.update!(qi: 0, total_experience: 0, last_online: now)
    character.start_spirit_expedition!(hours: 4, at: now)
    sign_in_as(user)

    get root_path(locale: :en)

    assert_response :success
    assert_equal 0, character.reload.qi
    assert_select ".offline-gain", text: /Spirit Expedition is underway/
  end

  test "does not show earned achievements on dashboard" do
    user = users(:one)
    character = user.character || user.create_character!
    character.character_achievements.create!(key: "first_star", earned_at: Time.current)
    sign_in_as(user)

    get root_path(locale: :en)

    assert_response :success
    assert_select ".achievements", false
    assert_no_match(/First Star/, response.body)
  end

  test "shows qi delta for recent event history" do
    user = users(:one)
    character = user.character || user.create_character!
    character.game_events.create!(
      event_key: "mysterious_item",
      outcome: "positive",
      title: "cultivation_events.mysterious_item.title",
      description: "cultivation_events.mysterious_item.positive_description",
      metadata: { "item_name_key" => "jade_pill" },
      qi_delta: 3_600,
      happened_at: Time.current
    )
    sign_in_as(user)

    get root_path(locale: :en)

    assert_response :success
    assert_select ".event-list", text: /\+3,600 Qi/
  end

  test "shows refreshable cultivation panel" do
    user = users(:one)
    sign_in_as(user)

    get cultivation_panel_path(locale: :en)

    assert_response :success
    assert_select "h1", "Jade River"
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
