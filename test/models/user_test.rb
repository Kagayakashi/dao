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
end
