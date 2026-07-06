require "test_helper"

class SectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @character = @user.character
    @character.update!(sect_key: nil, sect_rank: 0, sect_contribution: 0, sect_task_completed_at: nil, currency: 2_000, qi: 0, total_experience: 0)
    sign_in_as(@user)
  end

  test "shows sect choices before joining" do
    get sect_path(locale: :en)

    assert_response :success
    assert_select "h1", "Sect Hall"
    assert_select "li.action-card", 6
    assert_select "strong", "Azure Cloud Sect"
    leaderboard_path = leaderboard_sect_path(locale: :en, sect_key: "azure_cloud")
    assert_includes response.body, "href=\"#{leaderboard_path}\""
  end

  test "joins a sect" do
    post join_sect_path(locale: :en, sect_key: "azure_cloud")

    assert_redirected_to sect_path(locale: :en)
    @character.reload
    assert_equal "azure_cloud", @character.sect_key
    assert_equal 0, @character.sect_rank
  end

  test "performs daily sect task" do
    @character.update!(sect_key: "jade_river", sect_task_completed_at: nil)

    post task_sect_path(locale: :en)

    assert_redirected_to sect_path(locale: :en)
    @character.reload
    assert_equal 7_200, @character.qi
    assert_equal 2_105, @character.currency
    assert_equal 100, @character.sect_contribution
    assert_predicate @character.sect_task_completed_at, :present?
  end

  test "donates wen for contribution" do
    @character.update!(sect_key: "iron_mountain", currency: 1_000)

    post donate_sect_path(locale: :en)

    assert_redirected_to sect_path(locale: :en)
    @character.reload
    assert_equal 0, @character.currency
    assert_equal 50, @character.sect_contribution
  end

  test "donates multiple times at once" do
    @character.update!(sect_key: "iron_mountain", currency: 10_000)

    post donate_sect_path(locale: :en), params: { amount: 10 }

    assert_redirected_to sect_path(locale: :en)
    @character.reload
    assert_equal 0, @character.currency
    assert_equal 500, @character.sect_contribution
    assert_equal 10_000, @character.game_events.order(:created_at).last.metadata["wen"]
  end

  test "does not donate an invalid amount" do
    @character.update!(sect_key: "iron_mountain", currency: 1_000)

    post donate_sect_path(locale: :en), params: { amount: 0 }
    follow_redirect!

    assert_equal 1_000, @character.reload.currency
    assert_equal 0, @character.sect_contribution
    assert_select ".form-alert", text: /at least 1/
  end

  test "promotes sect rank" do
    @character.update!(sect_key: "scarlet_flame", sect_contribution: 500)

    post promote_sect_path(locale: :en)

    assert_redirected_to sect_path(locale: :en)
    @character.reload
    assert_equal 1, @character.sect_rank
    assert_equal 0, @character.sect_contribution
  end

  test "shows sect leaderboard by contribution rank and total qi" do
    @character.update!(sect_key: "azure_cloud", sect_rank: 0, sect_contribution: 100, total_experience: 1_000)
    users(:two).character.update!(sect_key: "azure_cloud", sect_rank: 1, sect_contribution: 100, total_experience: 500)

    get leaderboard_sect_path(locale: :en, sect_key: "azure_cloud")

    assert_response :success
    assert_select "h1", "Sect Leaderboard"
    assert_select ".leaderboard-entry:first-child", text: /Quiet Flame/
    assert_select ".leaderboard-entry:first-child", text: /100 contribution/
    assert_select ".leaderboard-entry:first-child", text: /Inner Disciple/
    assert_select ".pagination-nav", text: /Page 1 of 1/
  end

  test "defaults sect leaderboard to current character sect" do
    @character.update!(sect_key: "scarlet_flame", sect_contribution: 10)

    get leaderboard_sect_path(locale: :en)

    assert_response :success
    assert_select ".screen-note", text: /Scarlet Flame Sect/
  end

  test "shows empty sect leaderboard" do
    Character.where(sect_key: "silent_moon").update_all(sect_key: nil)

    get leaderboard_sect_path(locale: :en, sect_key: "silent_moon")

    assert_response :success
    assert_select ".empty-state", "No cultivators have joined this sect yet."
  end

  test "paginates sect leaderboard" do
    create_sect_members(12, sect_key: "jade_river")

    get leaderboard_sect_path(locale: :en, sect_key: "jade_river", page: 2)

    assert_response :success
    assert_select ".leaderboard-entry", 2
    assert_select ".leaderboard-entry:first-child .leaderboard-rank", text: /11/
    assert_select ".pagination-nav", text: /Page 2 of 2/
    assert_select ".pagination-nav a[href='#{leaderboard_sect_path(locale: :en, sect_key: "jade_river", page: 1)}']", text: "Previous"
  end

  private

  def create_sect_members(count, sect_key:)
    count.times do |index|
      user = User.create!(
        email_address: "sect-leaderboard-#{index}@example.com",
        password: "password",
        character_name: "Sect Member #{index}"
      )
      user.character.update!(sect_key:, sect_contribution: count - index)
    end
  end
end
