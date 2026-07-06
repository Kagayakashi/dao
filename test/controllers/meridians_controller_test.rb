require "test_helper"

class MeridiansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @character = @user.character
    @character.character_meridians.destroy_all
    @character.update!(realm: 1, star: 5, qi: 0, currency: 10_000, current_health: nil)
    sign_in_as(@user)
  end

  test "shows meridian chamber" do
    get meridians_path(locale: :en)

    assert_response :success
    assert_select "h1", "Meridian Chamber"
    assert_select "li.action-card", 12
    assert_select "strong", "Lung Meridian"
  end

  test "opens a meridian subpoint" do
    assert_difference -> { @character.game_events.where(event_key: "meridian_opening").count }, 1 do
      post open_meridians_path(locale: :en, key: "lung")
    end

    assert_redirected_to meridians_path(locale: :en)
    meridian = @character.character_meridians.find_by!(key: "lung")
    assert_equal 1, meridian.opened_subpoints
    assert_predicate meridian, :active?
  end

  test "does not activate more than three meridians" do
    %w[ lung stomach kidney ].each do |key|
      @character.character_meridians.create!(key:, opened_subpoints: 1, active: true)
    end
    @character.character_meridians.create!(key: "liver", opened_subpoints: 1)

    post activate_meridians_path(locale: :en, key: "liver")

    assert_redirected_to meridians_path(locale: :en)
    assert_equal "Only three meridians can be active at once.", flash[:alert]
    assert_not @character.character_meridians.find_by!(key: "liver").active?
  end
end
