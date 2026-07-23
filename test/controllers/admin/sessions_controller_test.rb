require "test_helper"

module Admin
  class SessionsControllerTest < ActionDispatch::IntegrationTest
    test "shows admin sign in" do
      get new_admin_session_path(locale: :en)

      assert_response :success
      assert_select "h1", "Admin Sign In"
      assert_select "h2", "Login Log"
      assert_select "dd", "No game user in cookies"
    end

    test "shows game session details from signed cookie" do
      user = users(:one)
      game_session = user.sessions.create!(created_at: Time.zone.local(2026, 7, 23, 8, 30), ip_address: "203.0.113.7")
      ActionDispatch::TestRequest.create.cookie_jar.tap do |cookie_jar|
        cookie_jar.signed[:session_id] = game_session.id
        cookies["session_id"] = cookie_jar[:session_id]
      end

      get new_admin_session_path(locale: :en)

      assert_response :success
      assert_select "dt", "Saved game user ID"
      assert_select "dd", user.id.to_s
      assert_select "dt", "Last game login"
      assert_select "dd", I18n.l(game_session.created_at, format: :long)
      assert_select "dt", "Last game login IP"
      assert_select "dd", "203.0.113.7"
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
