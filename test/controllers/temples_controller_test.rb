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
    assert_select ".daily-reward-card", text: /Realm 2, Star 3/
    assert_select "form button", "Pray"
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
end
