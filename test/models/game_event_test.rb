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

  test "formats qi delta with bonus metadata" do
    event = characters(:one).game_events.create!(
      event_key: "good_cultivation_place",
      outcome: "positive",
      title: "cultivation_events.good_cultivation_place.title",
      description: "cultivation_events.good_cultivation_place.description",
      metadata: { "qi" => 3_728, "base_qi" => 3_600, "qi_bonus" => 128 },
      qi_delta: 3_728,
      happened_at: Time.current
    )

    assert_equal "+3,600 (+128) Qi", event.localized_qi_delta
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

  test "localizes refinement event metadata" do
    event = characters(:one).game_events.create!(
      event_key: "artifact_refinement",
      outcome: "neutral",
      title: "artifact_refinements.events.title",
      description: "artifact_refinements.events.description",
      metadata: {
        "inventory_item_name_key" => "iron_dao_blade",
        "old_power_options" => [ { "key" => "power", "value" => 10 } ],
        "new_power_options" => [ { "key" => "power", "value" => 25 }, { "key" => "accuracy", "value" => 3.2 } ]
      },
      qi_delta: 0,
      happened_at: Time.current
    )

    assert_equal "Artifact Refinement", event.localized_title
    assert_equal "Iron Dao Blade was refined. Before: Power +10. Now: Power +25, Accuracy +3.2.", event.localized_description
  end

  test "localizes old refinement event metadata" do
    event = characters(:one).game_events.create!(
      event_key: "artifact_refinement",
      outcome: "neutral",
      title: "artifact_refinements.events.title",
      description: "artifact_refinements.events.description",
      metadata: { "inventory_item_name_key" => "iron_dao_blade", "old_power" => 10, "new_power" => 25 },
      qi_delta: 0,
      happened_at: Time.current
    )

    assert_equal "Iron Dao Blade was refined. Before: Power +10. Now: Power +25.", event.localized_description
  end

  test "localizes shop purchase event metadata" do
    event = characters(:one).game_events.create!(
      event_key: "shop_purchase",
      outcome: "positive",
      title: "shops.events.title",
      description: "shops.events.description",
      metadata: { "inventory_item_name_key" => "iron_dao_blade", "power_options" => [ { "key" => "power", "value" => 10 } ] },
      qi_delta: 0,
      happened_at: Time.current
    )

    assert_equal "Shop Purchase", event.localized_title
    assert_equal "Bought Iron Dao Blade with Power +10.", event.localized_description
  end

  test "localizes spirit expedition event metadata" do
    event = characters(:one).game_events.create!(
      event_key: "spirit_expedition",
      outcome: "positive",
      title: "spirit_expeditions.events.title",
      description: "spirit_expeditions.events.description",
      metadata: { "hours" => 4, "qi" => 21_600, "base_qi" => 21_600, "qi_bonus" => 0, "wen" => 80, "base_wen" => 80, "wen_bonus" => 0 },
      qi_delta: 21_600,
      happened_at: Time.current
    )

    assert_equal "Spirit Expedition", event.localized_title
    assert_equal "Returned from a 4h Spirit Expedition with 21,600 Qi and 80 Wen.", event.localized_description
  end

  test "localizes spirit expedition event without qi metadata" do
    event = characters(:one).game_events.create!(
      event_key: "spirit_expedition",
      outcome: "positive",
      title: "spirit_expeditions.events.title",
      description: "spirit_expeditions.events.description",
      metadata: { "hours" => 24, "wen" => 1_314 },
      qi_delta: 129_600,
      happened_at: Time.current
    )

    assert_equal "Returned from a 24h Spirit Expedition with 129,600 Qi and 1,314 Wen.", event.localized_description
  end

  test "localizes meridian opening event metadata" do
    event = characters(:one).game_events.create!(
      event_key: "meridian_opening",
      outcome: "positive",
      title: "meridians.events.opened.title",
      description: "meridians.events.opened.description",
      metadata: { "meridian_key" => "lung", "subpoint" => 1, "qi_cost" => 400, "wen_cost" => 5_000 },
      qi_delta: -400,
      happened_at: Time.current
    )

    assert_equal "Meridian Opened", event.localized_title
    assert_equal "Lung Meridian subpoint 1 opened, consuming 400 Qi and 5000 Wen.", event.localized_description
  end

  test "localizes sect event metadata" do
    event = characters(:one).game_events.create!(
      event_key: "sect_promotion",
      outcome: "positive",
      title: "sects.events.promotion.title",
      description: "sects.events.promotion.description",
      metadata: { "sect_key" => "azure_cloud", "rank_key" => "inner_disciple", "contribution" => 500 },
      qi_delta: 0,
      happened_at: Time.current
    )

    assert_equal "Sect Promotion", event.localized_title
    assert_equal "Rose within Azure Cloud Sect to Inner Disciple, spending 500 contribution.", event.localized_description
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
