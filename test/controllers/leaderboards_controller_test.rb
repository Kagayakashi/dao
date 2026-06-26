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
    assert_select ".leaderboard-entry:first-child a[href='#{character_path(users(:two).character, locale: :en)}']", text: /Quiet Flame/
    assert_select ".pagination-nav", text: /Page 1 of 1/
  end

  test "paginates characters ten per page" do
    create_leaderboard_characters(12)
    sign_in_as(users(:one))

    get leaderboard_path(locale: :en, page: 2)

    assert_response :success
    assert_select ".leaderboard-entry", 4
    assert_select ".leaderboard-entry:first-child .leaderboard-rank", text: /11/
    assert_select ".pagination-nav", text: /Page 2 of 2/
    assert_select ".pagination-nav a[href='#{leaderboard_path(locale: :en, page: 1)}']", text: "Previous"
    assert_select ".pagination-nav a", text: /Next/, count: 0
  end

  private

  def create_leaderboard_characters(count)
    users(:one).character.update!(total_experience: count + 2)
    users(:two).character.update!(total_experience: count + 1)

    count.times do |index|
      user = User.create!(
        email_address: "leaderboard-#{index}@example.com",
        password: "password",
        character_name: "Leaderboard #{index}"
      )
      user.character.update!(total_experience: count - index)
    end
  end
end
