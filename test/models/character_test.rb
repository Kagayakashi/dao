require "test_helper"

class CharacterTest < ActiveSupport::TestCase
  setup do
    @original_config = {
      stars_per_realm: Character.stars_per_realm,
      base_qi_required: Character.base_qi_required,
      realm_qi_growth: Character.realm_qi_growth,
      star_qi_growth: Character.star_qi_growth,
      base_qi_per_second: Character.base_qi_per_second,
      cultivation_multiplier: Character.cultivation_multiplier,
      offline_cultivation_multiplier: Character.offline_cultivation_multiplier,
      breakthrough_overflow_loss_range: Character.breakthrough_overflow_loss_range,
      base_power: Character.base_power,
      realm_power_multiplier: Character.realm_power_multiplier,
      star_power_multiplier: Character.star_power_multiplier,
      max_sparring_points: Character.max_sparring_points,
      sparring_recovery_duration: Character.sparring_recovery_duration,
      sparring_opponent_cooldown: Character.sparring_opponent_cooldown
    }

    Character.stars_per_realm = 9
    Character.base_qi_required = 100
    Character.realm_qi_growth = 1.0
    Character.star_qi_growth = 1.0
    Character.base_qi_per_second = 2
    Character.cultivation_multiplier = 1.0
    Character.offline_cultivation_multiplier = 1.0
    Character.breakthrough_overflow_loss_range = 10..65
    Character.base_power = 100
    Character.realm_power_multiplier = 2.0
    Character.star_power_multiplier = 0.12
    Character.max_sparring_points = 3
    Character.sparring_recovery_duration = 1.hour
    Character.sparring_opponent_cooldown = 3.hours

    @character = characters(:one)
    @character.update!(realm: 1, star: 1, qi: 0, total_experience: 0, last_online: Time.current)
  end

  teardown do
    @original_config.each { |name, value| Character.public_send("#{name}=", value) }
  end

  test "uses cultivation names for stored progression columns" do
    @character.realm = 3
    @character.star = 4
    @character.qi = 50

    assert_equal 3, @character.level
    assert_equal 4, @character.sublevel
    assert_equal 50, @character.experience
  end

  test "requires a character name" do
    @character.name = ""

    assert_not @character.valid?
  end

  test "uses a default character name" do
    character = User.create!(email_address: "default-name@example.com", password: "password").character

    assert_equal "Wandering Cultivator", character.name
  end

  test "defaults character gender to male" do
    character = User.create!(email_address: "default-gender@example.com", password: "password").character

    assert_predicate character, :male?
    assert_equal "Male", character.gender_name
    assert_equal "male_profile.png", character.profile_image_name
  end

  test "default qi requirements make first realm take about one day" do
    with_default_qi_requirements do
      total_qi = qi_required_for_realm(1)

      assert_in_delta 1.day.to_i, total_qi, 60
    end
  end

  test "default qi requirements make fifth realm take about one month" do
    with_default_qi_requirements do
      total_qi = qi_required_for_realm(5)

      assert_in_delta 30.days.to_i, total_qi, 30.minutes.to_i
    end
  end

  test "gains qi without advancing when requirement is not met" do
    gained_qi = @character.gain_qi(40)

    assert_equal 40, gained_qi
    assert_equal 1, @character.realm
    assert_equal 1, @character.star
    assert_equal 40, @character.qi
    assert_equal 40, @character.total_experience
  end

  test "calculates power from realm and star" do
    @character.update!(realm: 1, star: 1)
    assert_equal 100, @character.power

    @character.update!(realm: 1, star: 5)
    assert_equal 148, @character.power

    @character.update!(realm: 3, star: 2)
    assert_equal 448, @character.power
  end

  test "stores qi without automatic breakthrough" do
    @character.gain_qi(250)

    assert_equal 1, @character.realm
    assert_equal 1, @character.star
    assert_equal 250, @character.qi
    assert_equal 250, @character.total_experience
    assert_predicate @character, :ready_for_breakthrough?
  end

  test "breakthrough advances one star and keeps overflow qi" do
    @character.gain_qi(250)

    result = @character.breakthrough!(loss_percent: 10)

    assert_equal 1, @character.realm
    assert_equal 2, @character.star
    assert_equal 135, @character.qi
    assert_equal 15, result[:lost_qi]
    assert_equal 10, result[:loss_percent]
  end

  test "breakthrough returns false when qi is not enough" do
    @character.gain_qi(40)

    assert_not @character.breakthrough!
    assert_equal 1, @character.star
    assert_equal 40, @character.qi
  end

  test "awards first star achievement after breakthrough" do
    @character.gain_qi(100)
    @character.breakthrough!

    assert_includes @character.character_achievements.pluck(:key), "first_star"
    assert_equal "First Star", @character.earned_achievement_details.first[:name]
  end

  test "breakthrough advances realm after ninth star" do
    @character.update!(realm: 1, star: 9, qi: 0)

    @character.gain_qi(100)
    @character.breakthrough!(loss_percent: 10)

    assert_equal 2, @character.realm
    assert_equal 1, @character.star
    assert_equal 0, @character.qi
    assert_includes @character.character_achievements.pluck(:key), "first_realm"
  end

  test "awards thousand qi achievement" do
    @character.gain_qi(1_000)

    assert_includes @character.character_achievements.pluck(:key), "thousand_qi"
  end

  test "requires repeated manual breakthroughs across realm boundary" do
    @character.update!(realm: 1, star: 8, qi: 0)

    @character.gain_qi(300)
    @character.breakthrough!(loss_percent: 10)

    assert_equal 1, @character.realm
    assert_equal 9, @character.star
    assert_equal 180, @character.qi

    @character.breakthrough!(loss_percent: 10)

    assert_equal 2, @character.realm
    assert_equal 1, @character.star
    assert_equal 72, @character.qi
  end

  test "applies offline qi and updates last online time" do
    last_online = Time.zone.local(2026, 6, 18, 8, 0, 0)
    now = last_online + 90.seconds
    @character.update!(last_online: last_online)

    gained_qi = @character.cultivate_offline!(at: now)

    assert_equal 180, gained_qi
    @character.reload
    assert_equal 1, @character.realm
    assert_equal 1, @character.star
    assert_equal 180, @character.qi
    assert_equal 180, @character.total_experience
    assert_equal now, @character.last_online
  end

  test "admin qi adjustment recalculates multiple stars upward" do
    @character.admin_adjust_qi!(250)

    @character.reload
    assert_equal 1, @character.realm
    assert_equal 3, @character.star
    assert_equal 50, @character.qi
    assert_equal 250, @character.total_experience
  end

  test "admin qi adjustment can decrease stars" do
    @character.update!(realm: 1, star: 3, qi: 50, total_experience: 250)

    @character.admin_adjust_qi!(-160)

    @character.reload
    assert_equal 1, @character.realm
    assert_equal 1, @character.star
    assert_equal 90, @character.qi
    assert_equal 90, @character.total_experience
  end

  test "admin qi adjustment clamps below zero" do
    @character.update!(realm: 1, star: 2, qi: 10, total_experience: 110)

    @character.admin_adjust_qi!(-500)

    @character.reload
    assert_equal 1, @character.realm
    assert_equal 1, @character.star
    assert_equal 0, @character.qi
    assert_equal 0, @character.total_experience
  end

  test "spends one sparring point" do
    now = Time.zone.local(2026, 6, 18, 12, 0, 0)
    @character.update!(sparring_points: 3, sparring_recovered_at: 2.hours.ago)

    assert @character.spend_sparring_point!(at: now)

    @character.reload
    assert_equal 2, @character.sparring_points
    assert_equal now, @character.sparring_recovered_at
  end

  test "recovers one sparring point each hour up to the limit" do
    recovered_at = Time.zone.local(2026, 6, 18, 10, 0, 0)
    @character.update!(sparring_points: 1, sparring_recovered_at: recovered_at)

    @character.recover_sparring_points!(at: recovered_at + 90.minutes)

    @character.reload
    assert_equal 2, @character.sparring_points
    assert_equal recovered_at + 1.hour, @character.sparring_recovered_at

    @character.recover_sparring_points!(at: recovered_at + 3.hours)

    assert_equal 3, @character.reload.sparring_points
  end

  test "reports next sparring recovery time while below limit" do
    recovered_at = Time.zone.local(2026, 6, 18, 10, 0, 0)
    @character.update!(sparring_points: 2, sparring_recovered_at: recovered_at)

    assert_equal recovered_at + 1.hour, @character.sparring_recovery_due_at(at: recovered_at + 30.minutes)
  end

  test "marks character unavailable for sparring cooldown" do
    now = Time.zone.local(2026, 6, 18, 12, 0, 0)

    @character.mark_sparring_unavailable!(at: now)

    assert_equal now + 3.hours, @character.reload.sparring_available_at
    assert_not @character.available_for_sparring?(at: now + 2.hours)
    assert @character.available_for_sparring?(at: now + 3.hours)
  end

  private

  def with_default_qi_requirements
    Character.base_qi_required = 5_845
    Character.realm_qi_growth = 30**(1.0 / 4)
    Character.star_qi_growth = 1.12

    yield
  ensure
    Character.base_qi_required = 100
    Character.realm_qi_growth = 1.0
    Character.star_qi_growth = 1.0
  end

  def qi_required_for_realm(realm)
    (1..Character.stars_per_realm).sum do |star|
      @character.realm = realm
      @character.star = star
      @character.qi_required_for_next_star
    end
  end
end
