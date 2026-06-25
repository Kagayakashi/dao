require "test_helper"

class NewsControllerTest < ActionDispatch::IntegrationTest
  test "redirects guests to sign in" do
    get news_index_path(locale: :en)

    assert_redirected_to new_session_path(locale: :en)
  end

  test "shows crier news list with unread state" do
    news_post = create_news_post(title: "Heavenly Notice")
    sign_in_as(users(:one))

    get news_index_path(locale: :en)

    assert_response :success
    assert_select "h1", "Crier"
    assert_select ".news-entry--unread a[href='#{news_path(news_post, locale: :en)}']", text: /Heavenly Notice/
    assert_select ".news-entry__badge", "Unread"
    assert_select "form button", "Read all"
    assert_select ".global-header__item--unread[href='#{news_index_path(locale: :en)}']"
  end

  test "marks all news as read" do
    character = users(:one).character
    create_news_post(title: "First")
    create_news_post(title: "Second")
    sign_in_as(users(:one))

    assert_difference -> { character.news_reads.count }, 2 do
      post read_all_news_index_path(locale: :en)
    end

    assert_redirected_to news_index_path(locale: :en)
    follow_redirect!
    assert_select ".news-entry--unread", false
    assert_select "form button", text: /Read all/, count: 0
  end

  test "opens news and marks it as read" do
    character = users(:one).character
    news_post = create_news_post(title: "Read Me")
    sign_in_as(users(:one))

    assert_difference -> { character.news_reads.count }, 1 do
      get news_path(news_post, locale: :en)
    end

    assert_response :success
    assert_select "h1", "Read Me"
    assert_select ".news-body", text: /News body/

    get news_index_path(locale: :en)

    assert_select ".global-header__item--unread", false
  end

  private

  def create_news_post(title:)
    NewsPost.create!(title:, published_at: Time.current, body: "<p>News body</p>")
  end
end
