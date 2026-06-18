require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    get new_user_path(locale: :en)

    assert_response :success
    assert_select "h1", "Begin Cultivation"
  end

  test "create signs in user and creates named character" do
    assert_difference -> { User.count }, 1 do
      assert_difference -> { Character.count }, 1 do
        post users_path(locale: :en), params: {
          user: {
            character_name: "Cloud Root",
            email_address: "cloud-root@example.com",
            password: "password",
            password_confirmation: "password"
          }
        }
      end
    end

    assert_redirected_to root_path(locale: :en)
    assert cookies[:session_id]
    assert_equal "Cloud Root", User.find_by!(email_address: "cloud-root@example.com").character.name
  end

  test "create renders errors for invalid details" do
    assert_no_difference -> { User.count } do
      post users_path(locale: :en), params: { user: { character_name: "", email_address: "", password: "" } }
    end

    assert_response :unprocessable_entity
  end
end
