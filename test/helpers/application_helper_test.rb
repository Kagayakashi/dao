require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "alternate locale switches between supported locales" do
    I18n.with_locale(:en) { assert_equal :ru, alternate_locale }
    I18n.with_locale(:ru) { assert_equal :en, alternate_locale }
  end

  test "cultivation icon renders hidden inline svg" do
    html = cultivation_icon(:spark)

    assert_includes html, "<svg"
    assert_includes html, "thematic-icon"
    assert_includes html, "aria-hidden=\"true\""
    assert_includes html, "focusable=\"false\""
  end

  test "sparring recovery countdown formats remaining time" do
    character = characters(:one)

    travel_to Time.zone.local(2026, 6, 18, 12, 0, 0) do
      character.update!(sparring_points: 2, sparring_recovered_at: 30.minutes.ago)

      assert_equal "30:00", sparring_recovery_countdown(character)
    end
  end

  test "sparring recovery countdown is zero when focus is full" do
    character = characters(:one)
    character.update!(sparring_points: character.max_sparring_points)

    assert_equal "00:00", sparring_recovery_countdown(character)
  end
end
