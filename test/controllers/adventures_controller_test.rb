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
    assert_select "a[href='#{sparring_path(locale: :en)}']", "Wuxia Sparring"
    assert_select "a[href='#{spirit_expedition_path(locale: :en)}']", "Spirit Expedition"
    assert_select "a[href='#{news_index_path(locale: :en)}']", "Crier"
  end
end
