require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    get new_user_path(locale: :en)

    assert_response :success
    assert_select "h1", "Begin Cultivation"
    assert_select "input[name='user[email_address]']", false
    assert_select "input[name='user[password]']", false
    assert_select "select[name='user[character_gender]']"
  end

  test "create signs in temporary user and creates named character" do
    assert_difference -> { User.count }, 1 do
      assert_difference -> { Character.count }, 1 do
        post users_path(locale: :en), params: {
          user: {
            character_name: "Cloud Root",
            character_gender: "female"
          }
        }
      end
    end

    assert_redirected_to root_path(locale: :en)
    assert cookies[:session_id]
    user = User.order(:created_at).last
    assert_predicate user, :temporary?
    assert_match(/temporary-/, user.email_address)
    assert_equal "Cloud Root", user.character.name
    assert_predicate user.character, :female?
  end

  test "create renders errors for invalid details" do
    assert_no_difference -> { User.count } do
      post users_path(locale: :en), params: { user: { character_name: "", email_address: "", password: "" } }
    end

    assert_response :unprocessable_entity
  end
end
