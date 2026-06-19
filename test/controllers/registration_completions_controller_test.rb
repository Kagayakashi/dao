require "test_helper"

class RegistrationCompletionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "temporary-completion@example.test",
      password: "temporary-password",
      temporary: true,
      character_name: "Unsealed Reed"
    )
    @user.character.update!(qi: 0, total_experience: 0)
    sign_in_as(@user)
  end

  test "shows completion form for temporary user" do
    get new_registration_completion_path(locale: :en)

    assert_response :success
    assert_select "h1", "Complete Registration"
    assert_select "input[name='user[email_address]']"
    assert_select "input[name='user[password]']"
  end

  test "completes registration and grants qi reward" do
    post registration_completion_path(locale: :en), params: {
      user: {
        email_address: "sealed-reed@example.com",
        password: "password",
        password_confirmation: "password"
      }
    }

    assert_redirected_to character_path(@user.character, locale: :en)
    @user.reload
    assert_not @user.temporary?
    assert_equal "sealed-reed@example.com", @user.email_address
    assert_equal User::COMPLETION_REWARD_QI, @user.character.reload.qi
    assert_equal User::COMPLETION_REWARD_QI, @user.character.total_experience
  end

  test "renders error for invalid completion" do
    post registration_completion_path(locale: :en), params: {
      user: {
        email_address: "",
        password: "password",
        password_confirmation: "different"
      }
    }

    assert_response :unprocessable_entity
    assert_predicate @user.reload, :temporary?
    assert_equal 0, @user.character.reload.qi
  end

  test "redirects permanent user away from completion form" do
    @user.update!(temporary: false)

    get new_registration_completion_path(locale: :en)

    assert_redirected_to character_path(@user.character, locale: :en)
  end
end
