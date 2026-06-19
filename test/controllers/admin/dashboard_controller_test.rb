require "test_helper"

module Admin
  class DashboardControllerTest < ActionDispatch::IntegrationTest
    test "redirects unauthenticated admin to admin sign in" do
      get admin_root_path(locale: :en)

      assert_redirected_to new_admin_session_path(locale: :en)
    end

    test "shows admin menu" do
      sign_in_admin

      get admin_root_path(locale: :en)

      assert_response :success
      assert_select "h1", "Admin Panel"
      assert_select "a[href='#{new_admin_item_path(locale: :en)}']", "Create Item"
      assert_select "a[href='#{new_admin_qi_adjustment_path(locale: :en)}']", "Adjust Qi"
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
