require "test_helper"

module Admin
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    test "shows admin sign in" do
      get new_admin_session_path(locale: :en)

      assert_response :success
      assert_select "h1", "Admin Sign In"
      assert_select "h2", text: "Login Log", count: 0
    end

    test "signs in with credential password" do
      assert_difference -> { AdminLogin.count }, 1 do
        with_admin_authentication(true) do
          post admin_session_path(locale: :en), params: { password: "secret" }
        end
      end

      assert_redirected_to admin_root_path(locale: :en)
    end

    test "records game user id from signed cookie on admin sign in" do
      user = users(:one)
      game_session = user.sessions.create!
      ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
        cookie_jar.signed[:session_id] = game_session.id
        cookies["session_id"] = cookie_jar[:session_id]
      end

      with_admin_authentication(true) do
        post admin_session_path(locale: :en), params: { password: "secret" }
      end

      assert_redirected_to admin_root_path(locale: :en)
      assert_equal user.id, AdminLogin.order(:created_at).last.game_user_id
    end

    test "rejects invalid credential password" do
      assert_no_difference -> { AdminLogin.count } do
        with_admin_authentication(false) do
          post admin_session_path(locale: :en), params: { password: "wrong" }
        end
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
