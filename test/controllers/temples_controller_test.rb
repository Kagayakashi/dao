require "test_helper"

class TemplesControllerTest < ActionDispatch::IntegrationTest
  test "redirects guests to sign in" do
    get temple_path(locale: :en)

    assert_redirected_to new_session_path(locale: :en)
  end

  test "shows Temple of Heaven with scaled reward" do
    user = users(:one)
    character = user.character
    character.update!(realm: 2, star: 3, daily_reward_claimed_at: nil)
    sign_in_as(user)

    get temple_path(locale: :en)

    assert_response :success
    assert_select "h1", "Temple of Heaven"
    assert_select ".daily-reward-card", text: /1,350 Qi/
    assert_select ".daily-reward-card", text: /Adept, Star 3/
    assert_select "form button", "Pray"
    assert_select ".quiet-nav a[href='#{adventure_path(locale: :en)}']", "Adventure"
    assert_select ".quiet-nav a[href='#{root_path(locale: :en)}']", false
  end

  test "prays for daily reward" do
    user = users(:one)
    character = user.character
    character.update!(realm: 2, star: 3, qi: 0, total_experience: 0, daily_reward_claimed_at: nil)
    sign_in_as(user)

    post pray_temple_path(locale: :en)

    assert_redirected_to temple_path(locale: :en)
    character.reload
    assert_equal 1_350, character.qi
    assert_equal 1_350, character.total_experience
    assert_predicate character.daily_reward_claimed_at, :present?
  end

  test "does not pray before cooldown" do
    user = users(:one)
    character = user.character
    character.update!(qi: 0, total_experience: 0, daily_reward_claimed_at: Time.current)
    sign_in_as(user)

    post pray_temple_path(locale: :en)

    assert_redirected_to temple_path(locale: :en)
    assert_equal 0, character.reload.qi
  end

  test "blocks daily prayer during spirit expedition" do
    user = users(:one)
    character = user.character
    now = Time.current
    character.update!(qi: 0, total_experience: 0, daily_reward_claimed_at: nil, last_online: now)
    character.start_spirit_expedition!(hours: 4, at: now)
    sign_in_as(user)

    get temple_path(locale: :en)

    assert_response :success
    assert_select ".form-alert", text: /Daily prayer is unavailable/
    assert_select "form button[disabled]", "Pray"

    travel_to(now + 1.hour) do
      post pray_temple_path(locale: :en)
    end

    assert_redirected_to temple_path(locale: :en)
    assert_equal 0, character.reload.qi
    assert_nil character.daily_reward_claimed_at
  end
end
