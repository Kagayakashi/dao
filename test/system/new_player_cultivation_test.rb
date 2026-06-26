require "application_system_test_case"

class NewPlayerCultivationTest < ApplicationSystemTestCase
  test "new player starts cultivation and sees the dashboard" do
    visit new_user_path(locale: :en)

    fill_in "Cultivator name", with: "River Lotus"
    choose "Female"
    click_on "Enter the Dao"

    assert_current_path root_path(locale: :en), ignore_query: true
    assert_text "River Lotus"
    assert_text "Qi gathers"
    assert_text "Your cultivation begins."

    character = Character.order(:created_at).last
    assert_equal "River Lotus", character.name
    assert_predicate character, :female?
    assert_predicate character.user, :temporary?
  end
end
