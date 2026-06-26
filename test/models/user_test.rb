require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email_address)
  end

  test "creates a character when user is created" do
    user = User.create!(email_address: "cultivator@example.com", password: "password", character_name: "Little Alchemist")

    assert_predicate user.character, :present?
    assert_equal "Little Alchemist", user.character.name
    assert_equal 1, user.character.realm
    assert_equal 1, user.character.star
  end

  test "creates a character with selected gender" do
    user = User.create!(email_address: "gender@example.com", password: "password", character_name: "Moon Alchemist", character_gender: "female")

    assert_predicate user.character, :female?
  end

  test "complete registration clears temporary flag and grants reward" do
    user = User.create!(email_address: "temporary@example.test", password: "password", temporary: true, character_name: "Temporary Leaf")
    user.character.update!(qi: 0, total_experience: 0)

    user.complete_registration!(email_address: "leaf@example.com", password: "new-password", password_confirmation: "new-password")

    assert_not user.temporary?
    assert_equal "leaf@example.com", user.email_address
    assert_equal User::COMPLETION_REWARD_QI, user.character.qi
    assert_equal User::COMPLETION_REWARD_QI, user.character.total_experience
  end

  test "does not create a character with a duplicate name" do
    User.create!(email_address: "first-name@example.com", password: "password", character_name: "Still Reed")

    user = User.new(email_address: "second-name@example.com", password: "password", character_name: "Still Reed")

    assert_not user.valid?
    assert_includes user.errors[:character_name], "has already been taken"
  end
end
