require "test_helper"

module Admin
  class NewsPostsControllerTest < ActionDispatch::IntegrationTest
    test "redirects unauthenticated admin to admin sign in" do
      get admin_news_posts_path(locale: :en)

      assert_redirected_to new_admin_session_path(locale: :en)
    end

    test "shows news posts" do
      news_post = create_news_post(title: "Crier Notice")
      sign_in_admin

      get admin_news_posts_path(locale: :en)

      assert_response :success
      assert_select "h1", "News Posts"
      assert_select ".news-entry", text: /Crier Notice/
      assert_select "a[href='#{edit_admin_news_post_path(news_post, locale: :en)}']", "Edit"
    end

    test "creates news post" do
      sign_in_admin

      assert_difference -> { NewsPost.count }, 1 do
        post admin_news_posts_path(locale: :en), params: news_post_params(title: "New Crier Notice")
      end

      assert_redirected_to admin_news_posts_path(locale: :en)
      assert_equal "New Crier Notice", NewsPost.order(:created_at).last.title
      assert_equal "News body", NewsPost.order(:created_at).last.body.to_plain_text.strip
    end

    test "updates news post" do
      news_post = create_news_post(title: "Old Title")
      sign_in_admin

      patch admin_news_post_path(news_post, locale: :en), params: news_post_params(title: "New Title")

      assert_redirected_to admin_news_posts_path(locale: :en)
      assert_equal "New Title", news_post.reload.title
    end

    test "deletes news post" do
      news_post = create_news_post(title: "Old News")
      sign_in_admin

      assert_difference -> { NewsPost.count }, -1 do
        delete admin_news_post_path(news_post, locale: :en)
      end

      assert_redirected_to admin_news_posts_path(locale: :en)
    end

    private

    def create_news_post(title:)
      NewsPost.create!(title:, published_at: Time.current, body: "<p>News body</p>")
    end

    def news_post_params(title:)
      {
        news_post: {
          title:,
          published_at: Time.current,
          body: "<p>News body</p>"
        }
      }
    end

    def sign_in_admin
      with_admin_authentication(true) do
        post admin_session_path(locale: :en), params: { password: "secret" }
      end
    end

    def with_admin_authentication(result)
      original_method = CredentialPassword.method(:authenticate?)
      CredentialPassword.define_singleton_method(:authenticate?) { |_| result }
      yield
    ensure
      CredentialPassword.define_singleton_method(:authenticate?, original_method)
    end
  end
end
