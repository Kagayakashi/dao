require "test_helper"

module Admin
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    test "shows admin sign in" do
      get new_admin_session_path(locale: :en)

      assert_response :success
      assert_select "h1", "Admin Sign In"
    end

    test "signs in with credential password" do
      with_admin_authentication(true) do
        post admin_session_path(locale: :en), params: { password: "secret" }
      end

      assert_redirected_to admin_root_path(locale: :en)
    end

    test "rejects invalid credential password" do
      with_admin_authentication(false) do
        post admin_session_path(locale: :en), params: { password: "wrong" }
      end

      assert_redirected_to new_admin_session_path(locale: :en)
    end

    test "signs out admin" do
      with_admin_authentication(true) do
        post admin_session_path(locale: :en), params: { password: "secret" }
      end

      delete admin_session_path(locale: :en)

      assert_redirected_to new_admin_session_path(locale: :en)
    end

    private

    def with_admin_authentication(result)
      original_method = CredentialPassword.method(:authenticate?)
      CredentialPassword.define_singleton_method(:authenticate?) { |_| result }
      yield
    ensure
      CredentialPassword.define_singleton_method(:authenticate?, original_method)
    end
  end
end
