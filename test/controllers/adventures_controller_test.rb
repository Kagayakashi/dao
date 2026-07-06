require "test_helper"

class AdventuresControllerTest < ActionDispatch::IntegrationTest
  test "shows city adventure page" do
    user = users(:one)
    user.character.update!(sparring_points: 2, sparring_recovered_at: 30.minutes.ago)
    sign_in_as(user)

    get adventure_path(locale: :en)

    assert_response :success
    assert_select ".main-banner img[alt='Cultivation city'][src*='city']"
    assert_select "h1", "Adventure"
    assert_select ".sparring-card", false
    assert_select "a[href='#{temple_path(locale: :en)}']", "Temple of Heaven"
    assert_select "a[href='#{sparring_path(locale: :en)}']", "Sparring"
    assert_select "a[href='#{spirit_expedition_path(locale: :en)}']", "Spirit Expedition"
    assert_select "a[href='#{artifact_refinement_path(locale: :en)}']", "Artifact Refinement Hall"
    assert_select "a[href='#{shop_path(locale: :en)}']", "Shop"
    assert_select "a[href='#{meridians_path(locale: :en)}']", "Meridian Chamber"
    assert_select "a[href='#{sect_path(locale: :en)}']", "Sect Hall"
    assert_select "a[href='#{news_index_path(locale: :en)}']", "Crier"
  end
end
