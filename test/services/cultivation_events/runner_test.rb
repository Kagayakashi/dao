require "test_helper"

class CultivationEvents::RunnerTest < ActiveSupport::TestCase
  setup do
    @character = characters(:one)
    @opponent = characters(:two)
    @now = Time.zone.local(2026, 6, 18, 12, 0, 0)
    @character.update!(realm: 1, star: 1, qi: 5_000, total_experience: 0)
    @opponent.update!(realm: 2, star: 1, qi: 0)
  end

  test "good cultivation place grants one hour of qi and sets cooldown" do
    event = run_event(:good_cultivation_place)

    assert_equal "good_cultivation_place", event.event_key
    assert_equal "positive", event.outcome
    assert_equal 3_600, event.qi_delta
    assert_equal 8_600, @character.reload.qi
    assert_cooldown_set(:good_cultivation_place)
    assert_global_cooldown_set
  end

  test "global event cooldown prevents repeated events before next event time" do
    run_event(:good_cultivation_place)

    event = CultivationEvents::Runner.new(
      @character,
      now: @now + 30.minutes,
      rng: Random.new(1),
      forced_event_key: :mysterious_item,
      forced_item: { name: "Jade Pill", outcome: :positive, qi_hours: 1 }
    ).call

    assert_nil event
  end

  test "global event cooldown allows events after one hour" do
    run_event(:good_cultivation_place)

    event = CultivationEvents::Runner.new(
      @character,
      now: @now + 1.hour,
      rng: Random.new(1),
      forced_event_key: :mysterious_item,
      forced_item: { name: "Jade Pill", outcome: :positive, qi_hours: 1 }
    ).call

    assert_equal "mysterious_item", event.event_key
  end

  test "event on cooldown does not run" do
    @character.character_event_cooldowns.create!(event_key: "good_cultivation_place", next_event_at: @now + 10.minutes)

    event = run_event(:good_cultivation_place)

    assert_nil event
  end

  test "mysterious item can grant qi" do
    event = run_event(:mysterious_item, forced_item: { name: "Jade Pill", outcome: :positive, qi_hours: 1 })

    assert_equal "positive", event.outcome
    assert_equal 3_600, event.qi_delta
    assert_equal 8_600, @character.reload.qi
  end

  test "mysterious item can lose qi" do
    event = run_event(:mysterious_item, forced_item: { name: "Cracked Spirit Stone", outcome: :negative, qi_hours: -3 })

    assert_equal "negative", event.outcome
    assert_equal(-10_800, event.qi_delta)
    assert_equal 0, @character.reload.qi
  end

  test "mysterious item can be neutral" do
    event = run_event(:mysterious_item, forced_item: { name: "Dusty Talisman", outcome: :neutral, qi_hours: 0 })

    assert_equal "neutral", event.outcome
    assert_equal 0, event.qi_delta
    assert_equal 5_000, @character.reload.qi
  end

  test "stranger cultivator fight uses power to decide defeat" do
    event = run_event(:stranger_cultivator, forced_outcome: :fight)

    assert_equal "defeat", event.outcome
    assert_equal @opponent, event.related_character
    assert_equal(-3_600, event.qi_delta)
    assert_equal 1_400, @character.reload.qi
  end

  test "stranger cultivator peaceful meeting changes no qi" do
    event = run_event(:stranger_cultivator, forced_outcome: :peaceful)

    assert_equal "peaceful", event.outcome
    assert_equal 0, event.qi_delta
    assert_equal 5_000, @character.reload.qi
  end

  test "found equipment item creates inventory item" do
    @character.inventory_items.destroy_all

    event = run_event(:found_equipment_item)

    assert_equal "found_equipment_item", event.event_key
    assert_equal "positive", event.outcome
    assert_equal 1, @character.inventory_items.in_inventory.count
    assert_includes 1..5, @character.inventory_items.first.power_options.size
    assert_cooldown_equals(:found_equipment_item, @now + 1.day)
  end

  test "found equipment item respects full inventory" do
    @character.inventory_items.destroy_all
    10.times { |index| @character.create_inventory_item!(name: "Stored #{index}", equipment_kind: "weapon", power_options: []) }

    event = run_event(:found_equipment_item)

    assert_equal "full_inventory", event.outcome
    assert_equal 10, @character.inventory_items.in_inventory.count
  end

  private

  def run_event(event_key, forced_outcome: nil, forced_item: nil)
    CultivationEvents::Runner.new(
      @character,
      now: @now,
      rng: Random.new(1),
      forced_event_key: event_key,
      forced_outcome:,
      forced_item:
    ).call
  end

  def assert_cooldown_set(event_key)
    cooldown = @character.character_event_cooldowns.find_by!(event_key: event_key.to_s)

    assert_operator cooldown.next_event_at, :>=, @now + 30.minutes
    assert_operator cooldown.next_event_at, :<=, @now + 1.hour
  end

  def assert_cooldown_equals(event_key, expected_time)
    cooldown = @character.character_event_cooldowns.find_by!(event_key: event_key.to_s)

    assert_equal expected_time, cooldown.next_event_at
  end

  def assert_global_cooldown_set
    cooldown = @character.character_event_cooldowns.find_by!(event_key: CultivationEvents::Registry.global_event_key)

    assert_equal @now + 1.hour, cooldown.next_event_at
  end
end
