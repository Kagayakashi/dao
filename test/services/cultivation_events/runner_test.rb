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
      forced_item: { name_key: "jade_pill", outcome: :positive, qi_hours: 1 }
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
      forced_item: { name_key: "jade_pill", outcome: :positive, qi_hours: 1 }
    ).call

    assert_equal "mysterious_item", event.event_key
  end

  test "event on cooldown does not run" do
    @character.character_event_cooldowns.create!(event_key: "good_cultivation_place", next_event_at: @now + 10.minutes)

    event = run_event(:good_cultivation_place)

    assert_nil event
  end

  test "mysterious item can grant qi" do
    event = run_event(:mysterious_item, forced_item: { name_key: "jade_pill", outcome: :positive, qi_hours: 1 })

    assert_equal "positive", event.outcome
    assert_equal 3_600, event.qi_delta
    assert_equal 8_600, @character.reload.qi
  end

  test "events store translation keys and render in the current locale" do
    event = run_event(:mysterious_item, forced_item: { name_key: "jade_pill", outcome: :positive, qi_hours: 1 })

    assert_equal "cultivation_events.mysterious_item.title", event.title
    assert_equal "cultivation_events.mysterious_item.positive_description", event.description
    assert_equal({ "item_name_key" => "jade_pill" }, event.metadata)

    I18n.with_locale(:ru) do
      assert_equal "Таинственный предмет", event.localized_title
      assert_equal "Вы очистили Нефритовая пилюля и получили всплеск Ци.", event.localized_description
    end
  end

  test "mysterious item can lose qi" do
    event = run_event(:mysterious_item, forced_item: { name_key: "cracked_spirit_stone", outcome: :negative, qi_hours: -3 })

    assert_equal "negative", event.outcome
    assert_equal(-10_800, event.qi_delta)
    assert_equal 0, @character.reload.qi
  end

  test "mysterious item can be neutral" do
    event = run_event(:mysterious_item, forced_item: { name_key: "dusty_talisman", outcome: :neutral, qi_hours: 0 })

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
    assert @opponent.current_health.nil? || @opponent.current_health < @opponent.health
  end

  test "stranger cultivator fight reduces opponent health" do
    @opponent.update!(current_health: nil)

    event = run_event(:stranger_cultivator, forced_outcome: :fight)

    assert_includes %w[victory defeat], event.outcome
  end

  test "stranger cultivator fight creates a reciprocal log for the related character" do
    assert_difference -> { @character.game_events.count }, 1 do
      assert_difference -> { @opponent.game_events.count }, 1 do
        run_event(:stranger_cultivator, forced_outcome: :fight)
      end
    end

    related_event = @opponent.game_events.order(:created_at).last

    assert_equal "stranger_cultivator", related_event.event_key
    assert_equal "victory", related_event.outcome
    assert_equal @character, related_event.related_character
    assert_equal 0, related_event.qi_delta
    assert_equal "Quiet Flame", @opponent.reload.name
    assert_equal "You crossed paths with Jade River. A short clash ended in your victory.", related_event.localized_description
  end

  test "stranger cultivator peaceful meeting changes no qi" do
    event = run_event(:stranger_cultivator, forced_outcome: :peaceful)

    assert_equal "peaceful", event.outcome
    assert_equal 0, event.qi_delta
    assert_equal 5_000, @character.reload.qi
  end

  test "stranger cultivator peaceful meeting creates a reciprocal log for the related character" do
    assert_difference -> { @opponent.game_events.count }, 1 do
      run_event(:stranger_cultivator, forced_outcome: :peaceful)
    end

    related_event = @opponent.game_events.order(:created_at).last

    assert_equal "peaceful", related_event.outcome
    assert_equal @character, related_event.related_character
    assert_equal "You met Jade River and exchanged quiet words about the Dao.", related_event.localized_description
  end

  test "found equipment item creates inventory item" do
    @character.inventory_items.destroy_all

    event = run_event(:found_equipment_item)
    item = @character.inventory_items.in_inventory.first

    assert_equal "found_equipment_item", event.event_key
    assert_equal "positive", event.outcome
    assert_equal 1, @character.inventory_items.in_inventory.count
    assert_equal 2, item.power_options.size
    assert_includes I18n.t("inventory_items.item_keys.#{item.equipment_kind}"), item.name
    assert_equal({ "inventory_item_name_key" => item.name }, event.metadata)
    assert_empty item.power_options.pluck("key") - %w[ power health defense evasion accuracy critical_rate ]
    assert_cooldown_equals(:found_equipment_item, @now + 1.day)
  end

  test "found equipment item stores locale neutral item key" do
    @character.inventory_items.destroy_all

    I18n.with_locale(:ru) do
      run_event(:found_equipment_item)
    end

    item = @character.inventory_items.in_inventory.first
    assert_includes I18n.t("inventory_items.item_keys.#{item.equipment_kind}"), item.name

    I18n.with_locale(:ru) do
      assert_equal I18n.t("inventory_items.names.#{item.name}"), item.localized_name
    end
  end

  test "found equipment item respects full inventory" do
    @character.inventory_items.destroy_all
    10.times { |index| @character.create_inventory_item!(name: "iron_dao_blade", equipment_kind: "weapon", power_options: [], metadata: { "test_slot" => index }) }

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
