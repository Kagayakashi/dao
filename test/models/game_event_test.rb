require "test_helper"

class GameEventTest < ActiveSupport::TestCase
  test "localizes stored translation keys using current locale" do
    event = characters(:one).game_events.create!(
      event_key: "mysterious_item",
      outcome: "positive",
      title: "cultivation_events.mysterious_item.title",
      description: "cultivation_events.mysterious_item.positive_description",
      metadata: { "item_name_key" => "jade_pill" },
      qi_delta: 3_600,
      happened_at: Time.current
    )

    I18n.with_locale(:en) do
      assert_equal "Mysterious Item", event.localized_title
      assert_equal "You refined Jade Pill and gained a surge of Qi.", event.localized_description
    end

    I18n.with_locale(:ru) do
      assert_equal "Таинственный предмет", event.localized_title
      assert_equal "Вы очистили Нефритовая пилюля и получили всплеск Ци.", event.localized_description
    end
  end

  test "formats qi delta for display" do
    positive_event = characters(:one).game_events.create!(
      event_key: "mysterious_item",
      outcome: "positive",
      title: "cultivation_events.mysterious_item.title",
      description: "cultivation_events.mysterious_item.positive_description",
      metadata: { "item_name_key" => "jade_pill" },
      qi_delta: 3_600,
      happened_at: Time.current
    )
    negative_event = characters(:one).game_events.create!(
      event_key: "mysterious_item",
      outcome: "negative",
      title: "cultivation_events.mysterious_item.title",
      description: "cultivation_events.mysterious_item.negative_description",
      metadata: { "item_name_key" => "cracked_spirit_stone" },
      qi_delta: -10_800,
      happened_at: Time.current
    )
    neutral_event = characters(:one).game_events.create!(
      event_key: "mysterious_item",
      outcome: "neutral",
      title: "cultivation_events.mysterious_item.title",
      description: "cultivation_events.mysterious_item.neutral_description",
      metadata: { "item_name_key" => "dusty_talisman" },
      qi_delta: 0,
      happened_at: Time.current
    )

    assert_equal "+3,600 Qi", positive_event.localized_qi_delta
    assert_equal "-10,800 Qi", negative_event.localized_qi_delta
    assert_nil neutral_event.localized_qi_delta
  end

  test "localizes equipment item names from stored event metadata" do
    event = characters(:one).game_events.create!(
      event_key: "found_equipment_item",
      outcome: "positive",
      title: "cultivation_events.found_equipment_item.title",
      description: "cultivation_events.found_equipment_item.description",
      metadata: { "inventory_item_name_key" => "iron_dao_blade" },
      qi_delta: 0,
      happened_at: Time.current
    )

    I18n.with_locale(:en) do
      assert_equal "You found Iron Dao Blade and placed it in your inventory.", event.localized_description
    end

    I18n.with_locale(:ru) do
      assert_equal "Вы нашли Железный клинок Дао и положили его в инвентарь.", event.localized_description
    end
  end

  test "does not show raw interpolation when equipment event item metadata is missing" do
    event = characters(:one).game_events.create!(
      event_key: "found_equipment_item",
      outcome: "positive",
      title: "cultivation_events.found_equipment_item.title",
      description: "cultivation_events.found_equipment_item.description",
      metadata: {},
      qi_delta: 0,
      happened_at: Time.current
    )

    assert_equal "You found a treasure and placed it in your inventory.", event.localized_description
  end

  test "localizes metadata interpolation keys" do
    event = characters(:one).game_events.create!(
      event_key: "stranger_cultivator",
      outcome: "peaceful",
      title: "cultivation_events.stranger_cultivator.title",
      description: "cultivation_events.stranger_cultivator.peaceful_description",
      metadata: { "name_i18n_key" => "cultivation_events.stranger_cultivator.passing_cultivator" },
      qi_delta: 0,
      happened_at: Time.current
    )

    I18n.with_locale(:en) do
      assert_equal "You met a passing cultivator and exchanged quiet words about the Dao.", event.localized_description
    end

    I18n.with_locale(:ru) do
      assert_equal "Вы встретили проходящий культиватор и спокойно поговорили о Дао.", event.localized_description
    end
  end

  test "uses related character name without storing it in metadata" do
    event = characters(:one).game_events.create!(
      event_key: "stranger_cultivator",
      outcome: "victory",
      title: "cultivation_events.stranger_cultivator.title",
      description: "cultivation_events.stranger_cultivator.victory_description",
      metadata: {},
      related_character: characters(:two),
      qi_delta: 3_600,
      happened_at: Time.current
    )

    assert_equal({}, event.metadata)
    assert_equal "You crossed paths with Quiet Flame. A short clash ended in your victory.", event.localized_description
  end

  test "falls back to generic stranger name without stored text" do
    event = characters(:one).game_events.create!(
      event_key: "stranger_cultivator",
      outcome: "peaceful",
      title: "cultivation_events.stranger_cultivator.title",
      description: "cultivation_events.stranger_cultivator.peaceful_description",
      metadata: {},
      qi_delta: 0,
      happened_at: Time.current
    )

    assert_equal "You met a passing cultivator and exchanged quiet words about the Dao.", event.localized_description
  end
end
