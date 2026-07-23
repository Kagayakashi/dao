require "test_helper"

module Admin
  class DashboardControllerTest < ActionDispatch::IntegrationTest
    test "redirects unauthenticated admin to admin sign in" do
      get admin_root_path(locale: :en)

      assert_redirected_to new_admin_session_path(locale: :en)
    end

    test "shows admin menu" do
      AdminLogin.delete_all
      sign_in_admin

      get admin_root_path(locale: :en)

      assert_response :success
      assert_select "h1", "Admin Panel"
      assert_select "a[href='#{new_admin_item_path(locale: :en)}']", "Create Item"
      assert_select "a[href='#{new_admin_qi_adjustment_path(locale: :en)}']", "Adjust Qi"
      assert_select "a[href='#{admin_news_posts_path(locale: :en)}']", "News Posts"
      assert_select "h2", "Login Log"
      assert_select "caption", "Last 5 admin logins"
    end

    test "shows last five saved admin logins" do
      sign_in_admin
      AdminLogin.delete_all
      user = users(:one)
      oldest_login = AdminLogin.create!(created_at: Time.zone.local(2026, 7, 23, 8, 24), ip_address: "203.0.113.1", game_user_id: user.id)
      admin_logins = 5.times.map do |index|
        AdminLogin.create!(created_at: Time.zone.local(2026, 7, 23, 8, 25 + index), ip_address: "203.0.113.#{index + 2}", game_user_id: user.id)
      end

      get admin_root_path(locale: :en)

      assert_response :success
      assert_select "caption", "Last 5 admin logins"
      admin_logins.reverse_each do |admin_login|
        assert_select "td", I18n.l(admin_login.created_at, format: :long)
        assert_select "td", admin_login.ip_address
      end
      assert_select "td", text: oldest_login.ip_address, count: 0
    end

    private

    def sign_in_admin
      original_method = CredentialPassword.method(:authenticate?)
      CredentialPassword.define_singleton_method(:authenticate?) { |_| true }
      post admin_session_path(locale: :en), params: { password: "secret" }
    ensure
      CredentialPassword.define_singleton_method(:authenticate?, original_method)
    end
  end
end
