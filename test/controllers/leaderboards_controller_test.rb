require "test_helper"

class LeaderboardsControllerTest < ActionDispatch::IntegrationTest
  test "redirects guests to sign in" do
    get leaderboard_path(locale: :en)

    assert_redirected_to new_session_path(locale: :en)
  end

  test "shows characters by total qi" do
    users(:one).character.update!(total_experience: 100)
    users(:two).character.update!(total_experience: 500)
    sign_in_as(users(:one))

    get leaderboard_path(locale: :en)

    assert_response :success
    assert_select "h1", "Leaderboard"
    assert_select ".leaderboard-entry:first-child", text: /Quiet Flame/
    assert_select ".leaderboard-entry:first-child", text: /500 Qi/
    assert_select ".leaderboard-entry:first-child", text: /Power/
  end
end
