require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "reset email contains reset link and recipient" do
    user = users(:one)

    email = PasswordsMailer.reset(user)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ user.email_address ], email.to
    assert_equal "Reset your password", email.subject
    assert_match %r{http://example\.com/passwords/.+/edit}, email.html_part.body.to_s
    assert_match %r{http://example\.com/passwords/.+/edit}, email.text_part.body.to_s
    assert_match "This link will expire", email.html_part.body.to_s
  end
end
