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
      combat_stat_config: Character.combat_stat_config,
      health_recovery_interval: Character.health_recovery_interval,
      health_recovery_percent: Character.health_recovery_percent,
      max_sparring_points: Character.max_sparring_points,
      sparring_recovery_duration: Character.sparring_recovery_duration,
      daily_reward_base_qi: Character.daily_reward_base_qi,
      daily_reward_realm_bonus_qi: Character.daily_reward_realm_bonus_qi,
      daily_reward_star_bonus_qi: Character.daily_reward_star_bonus_qi,
      daily_reward_cooldown: Character.daily_reward_cooldown,
      spirit_expedition_durations: Character.spirit_expedition_durations,
      spirit_expedition_extended_reward_multiplier: Character.spirit_expedition_extended_reward_multiplier,
      spirit_expedition_wen_reward_range: Character.spirit_expedition_wen_reward_range,
      spirit_expedition_donation_currency_chance: Character.spirit_expedition_donation_currency_chance,
      spirit_expedition_instant_completion_cost: Character.spirit_expedition_instant_completion_cost
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
    Character.combat_stat_config = CombatStats::CharacterStats::DEFAULT_CONFIG
    Character.health_recovery_interval = 10.minutes
    Character.health_recovery_percent = 5
    Character.max_sparring_points = 3
    Character.sparring_recovery_duration = 10.minutes
    Character.daily_reward_base_qi = 1_000
    Character.daily_reward_realm_bonus_qi = 250
    Character.daily_reward_star_bonus_qi = 50
    Character.daily_reward_cooldown = 1.day
    Character.spirit_expedition_durations = [ 1, 4, 12, 24 ]
    Character.spirit_expedition_extended_reward_multiplier = 0.75
    Character.spirit_expedition_wen_reward_range = 50..100
    Character.spirit_expedition_donation_currency_chance = 0.05
    Character.spirit_expedition_instant_completion_cost = 1

    @character = characters(:one)
    @character.update!(realm: 1, star: 1, qi: 0, total_experience: 0, last_online: Time.current, currency: 0, donation_currency: 0, current_health: nil, health_recovered_at: Time.current, spirit_expedition_started_at: nil, spirit_expedition_ends_at: nil, spirit_expedition_duration_hours: nil)
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

  test "applies positive qi delta as gained qi" do
    @character.apply_qi_delta!(40)

    @character.reload
    assert_equal 40, @character.qi
    assert_equal 40, @character.total_experience
  end

  test "applies negative qi delta without dropping below zero" do
    @character.update!(qi: 20, total_experience: 100)

    @character.apply_qi_delta!(-50)

    @character.reload
    assert_equal 0, @character.qi
    assert_equal 100, @character.total_experience
  end

  test "applies zero qi delta without changing character" do
    @character.update!(qi: 20, total_experience: 100)

    assert_no_changes -> { @character.reload.updated_at } do
      @character.apply_qi_delta!(0)
    end
  end

  test "calculates power from realm and star" do
    @character.update!(realm: 1, star: 1)
    assert_equal 100, @character.power

    @character.update!(realm: 1, star: 5)
    assert_equal 148, @character.power

    @character.update!(realm: 3, star: 2)
    assert_equal 448, @character.power
  end

  test "calculates combat stats from realm and star" do
    @character.update!(realm: 1, star: 1)

    assert_equal({ damage: 100, health: 975, defense: 35, evasion: 20, accuracy: 100, critical_rate: 5 }, @character.combat_stats)

    @character.update!(realm: 2, star: 5)

    assert_equal 296, @character.damage
    assert_equal 2_886, @character.health
    assert_equal 104, @character.defense
    assert_equal 46, @character.evasion
    assert_equal 126, @character.accuracy
    assert_equal 5, @character.critical_rate
  end

  test "keeps equal level no item survivability stable across realms" do
    [ [ 1, 1 ], [ 2, 5 ], [ 6, 1 ] ].each do |realm, star|
      @character.update!(realm:, star:)

      effective_damage = @character.damage - @character.defense

      assert_equal 15, @character.health / effective_damage
    end
  end

  test "keeps equal level no item hit chance stable across realms" do
    [ [ 1, 1 ], [ 2, 5 ], [ 6, 1 ] ].each do |realm, star|
      @character.update!(realm:, star:)

      assert_equal 80, @character.accuracy - @character.evasion
    end
  end

  test "adds equipped item stats to combat stats and gear score" do
    @character.inventory_items.destroy_all
    @character.update!(realm: 1, star: 1)
    item = @character.create_inventory_item!(
      name: "iron_dao_blade",
      equipment_kind: "weapon",
      power_options: [ { "key" => "power", "value" => 10 }, { "key" => "accuracy", "value" => 2.5 } ]
    )

    @character.equip_item!(item)

    assert_equal 110, @character.damage
    assert_equal 102.5, @character.accuracy
    assert_equal 13, @character.gear_score
  end

  test "recovers five percent health every ten minutes" do
    now = Time.zone.local(2026, 6, 18, 12, 0, 0)
    @character.update!(current_health: 100, health_recovered_at: now - 20.minutes)

    @character.recover_health!(at: now)

    assert_equal 197, @character.current_health
    assert_equal now, @character.health_recovered_at
  end

  test "damage cannot reduce current health below one" do
    @character.update!(current_health: 10)

    @character.take_damage!(100)

    assert_equal 1, @character.current_health
  end

  test "realm five full evasion accessories evade around sixty nine percent against equal weapon accuracy" do
    attacker = users(:two).character
    defender = @character
    [ attacker, defender ].each do |character|
      character.inventory_items.destroy_all
      character.update!(realm: 5, star: 1)
    end

    equip_item_with_options(attacker, "iron_dao_blade", "weapon", [ { "key" => "power", "value" => 0 }, { "key" => "accuracy", "value" => realm_five_item_max(:accuracy) } ])
    %w[ cloud_ring jade_band old_dragon_pendant ].each do |name|
      equipment_kind = name.include?("pendant") ? "pendant" : "ring"
      equip_item_with_options(defender, name, equipment_kind, [ { "key" => "evasion", "value" => realm_five_item_max(:evasion) } ])
    end

    evade_chance = 100 - (attacker.accuracy - defender.evasion)

    assert_in_delta 69, evade_chance, 1.5
  end

  test "realm five full critical accessories reach around twenty seven percent critical rate" do
    @character.inventory_items.destroy_all
    @character.update!(realm: 5, star: 1)
    %w[ cloud_ring jade_band old_dragon_pendant ].each do |name|
      equipment_kind = name.include?("pendant") ? "pendant" : "ring"
      equip_item_with_options(@character, name, equipment_kind, [ { "key" => "critical_rate", "value" => realm_five_item_max(:critical_rate) } ])
    end

    assert_in_delta 27, @character.critical_rate, 0.5
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

  test "recovers one sparring point each ten minutes up to the limit" do
    recovered_at = Time.zone.local(2026, 6, 18, 10, 0, 0)
    @character.update!(sparring_points: 1, sparring_recovered_at: recovered_at)

    @character.recover_sparring_points!(at: recovered_at + 10.minutes)

    @character.reload
    assert_equal 2, @character.sparring_points
    assert_equal recovered_at + 10.minutes, @character.sparring_recovered_at

    @character.recover_sparring_points!(at: recovered_at + 15.minutes)

    assert_equal 2, @character.reload.sparring_points
  end

  test "reports next sparring recovery time while below limit" do
    recovered_at = Time.zone.local(2026, 6, 18, 10, 0, 0)
    @character.update!(sparring_points: 2, sparring_recovered_at: recovered_at)

    assert_equal recovered_at + 10.minutes, @character.sparring_recovery_due_at(at: recovered_at + 5.minutes)
  end

  test "available for sparring only when health is above twenty five percent" do
    @character.update!(realm: 1, star: 1, current_health: nil, health_recovered_at: Time.current)

    assert @character.available_for_sparring?

    @character.update!(current_health: (@character.health * 25 / 100) + 1)

    assert @character.available_for_sparring?

    @character.update!(current_health: @character.health * 25 / 100)

    assert_not @character.available_for_sparring?

    @character.update!(current_health: 1)

    assert_not @character.available_for_sparring?
  end

  test "claims daily reward when ready" do
    now = Time.zone.local(2026, 6, 18, 12, 0, 0)
    @character.update!(realm: 2, star: 3)

    gained_qi = @character.claim_daily_reward!(at: now)

    @character.reload
    assert_equal 1_350, gained_qi
    assert_equal 1_350, @character.qi
    assert_equal 1_350, @character.total_experience
    assert_equal now, @character.daily_reward_claimed_at
  end

  test "daily reward scales by realm and star" do
    @character.update!(realm: 3, star: 4)

    assert_equal 1_650, @character.daily_reward_qi
  end

  test "does not claim daily reward before cooldown" do
    now = Time.zone.local(2026, 6, 18, 12, 0, 0)
    @character.update!(daily_reward_claimed_at: now - 1.hour)

    assert_not @character.claim_daily_reward!(at: now)

    @character.reload
    assert_equal 0, @character.qi
    assert_equal now + 23.hours, @character.daily_reward_available_at(at: now)
  end

  test "starts spirit expedition with an allowed duration" do
    now = Time.zone.local(2026, 6, 18, 12, 0, 0)

    assert @character.start_spirit_expedition!(hours: 4, at: now)

    @character.reload
    assert_equal now, @character.spirit_expedition_started_at
    assert_equal now + 4.hours, @character.spirit_expedition_ends_at
    assert_equal 4, @character.spirit_expedition_duration_hours
  end

  test "does not gain passive qi during active spirit expedition" do
    now = Time.zone.local(2026, 6, 18, 12, 0, 0)
    @character.start_spirit_expedition!(hours: 4, at: now)

    gained_qi = @character.cultivate_offline!(at: now + 2.hours)

    assert_equal 0, gained_qi
    assert_equal 0, @character.reload.qi
  end

  test "completes one hour spirit expedition without reward reduction" do
    now = Time.zone.local(2026, 6, 18, 12, 0, 0)
    @character.start_spirit_expedition!(hours: 1, at: now)

    result = @character.complete_spirit_expedition!(at: now + 1.hour, wen_per_hour: 80, donation_currency_roll: 0.99)

    @character.reload
    assert_equal({ qi: 7_200, wen: 80, donation_currency: 0 }, result)
    assert_equal 7_200, @character.qi
    assert_equal 7_200, @character.total_experience
    assert_equal 80, @character.currency
    assert_equal 0, @character.donation_currency
    assert_nil @character.spirit_expedition_ends_at
    event = @character.game_events.order(:created_at).last
    assert_equal "spirit_expedition", event.event_key
    assert_equal 1, event.metadata.fetch("hours")
    assert_equal 80, event.metadata.fetch("wen")
  end

  test "one hour spirit expedition can reward donation currency" do
    now = Time.zone.local(2026, 6, 18, 12, 0, 0)
    @character.start_spirit_expedition!(hours: 1, at: now)

    result = @character.complete_spirit_expedition!(at: now + 1.hour, wen_per_hour: 80, donation_currency_roll: 0.04)

    @character.reload
    assert_equal({ qi: 7_200, wen: 80, donation_currency: 1 }, result)
    assert_equal 1, @character.donation_currency
  end

  test "reduces extended spirit expedition rewards by twenty five percent" do
    now = Time.zone.local(2026, 6, 18, 12, 0, 0)
    @character.start_spirit_expedition!(hours: 4, at: now)

    result = @character.complete_spirit_expedition!(at: now + 4.hours, wen_per_hour: 80, donation_currency_roll: 0.0)

    @character.reload
    assert_equal({ qi: 21_600, wen: 240, donation_currency: 0 }, result)
    assert_equal 21_600, @character.qi
    assert_equal 240, @character.currency
    assert_equal 0, @character.donation_currency
  end

  test "completes active spirit expedition immediately for liang" do
    now = Time.zone.local(2026, 6, 18, 12, 0, 0)
    @character.update!(donation_currency: 1)
    @character.start_spirit_expedition!(hours: 4, at: now)

    result = @character.complete_spirit_expedition_now!(at: now + 30.minutes)

    @character.reload
    assert_equal({ qi: 21_600, wen: result[:wen], donation_currency: 0 }, result)
    assert_nil @character.spirit_expedition_ends_at
    assert_equal 0, @character.donation_currency
    assert_equal 1, @character.game_events.where(event_key: "spirit_expedition").count
  end

  test "does not complete active spirit expedition immediately without liang" do
    now = Time.zone.local(2026, 6, 18, 12, 0, 0)
    @character.start_spirit_expedition!(hours: 4, at: now)

    assert_not @character.complete_spirit_expedition_now!(at: now + 30.minutes)
    assert @character.reload.spirit_expedition_active?(at: now + 30.minutes)
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

  def equip_item_with_options(character, name, equipment_kind, power_options)
    item = character.create_inventory_item!(name:, equipment_kind:, power_options:)
    character.equip_item!(item)
  end

  def realm_five_item_max(stat_key)
    character = Character.new(level: 5, sublevel: 1)

    InventoryItems::StatRoll.new(character, stat_key:).range.end
  end
end
