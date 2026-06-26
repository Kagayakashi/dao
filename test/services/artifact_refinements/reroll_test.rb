require "test_helper"

module ArtifactRefinements
  class RerollTest < ActiveSupport::TestCase
    test "rerolls item power with wen and creates event" do
      character = users(:one).character
      item = character.create_inventory_item!(name: "iron_dao_blade", equipment_kind: "weapon", power_options: [ { "key" => "power", "value" => 10 } ])
      character.update!(currency: Reroll::WEN_COST, donation_currency: 0)

      assert_difference -> { character.game_events.count }, 1 do
        result = Reroll.new(character, item_id: item.id, payment: "wen", rng: FixedRng.new(option_roll: 0.0, values: [ 25 ])).call

        assert_predicate result, :success?
        assert_equal item, result.item
      end

      assert_equal 0, character.reload.currency
      assert_equal [ { "key" => "power", "value" => 25 } ], item.reload.power_options

      event = character.game_events.order(:created_at).last
      assert_equal "artifact_refinement", event.event_key
      assert_equal "iron_dao_blade", event.metadata.fetch("inventory_item_name_key")
      assert_equal 10, event.metadata.fetch("old_power")
      assert_equal 25, event.metadata.fetch("new_power")
    end

    test "rerolls item power with liang" do
      character = users(:one).character
      item = character.create_inventory_item!(name: "cloud_ring", equipment_kind: "ring", power_options: [ { "key" => "power", "value" => 12 } ])
      character.update!(currency: 0, donation_currency: Reroll::LIANG_COST)

      result = Reroll.new(character, item_id: item.id, payment: "liang", rng: FixedRng.new(option_roll: 0.0, values: [ 30 ])).call

      assert_predicate result, :success?
      assert_equal 0, character.reload.donation_currency
      assert_equal [ { "key" => "power", "value" => 30 } ], item.reload.power_options
    end

    test "fails without enough currency" do
      character = users(:one).character
      item = character.create_inventory_item!(name: "old_dragon_pendant", equipment_kind: "pendant", power_options: [ { "key" => "power", "value" => 12 } ])
      character.update!(currency: Reroll::WEN_COST - 1, donation_currency: 0)

      assert_no_difference -> { character.game_events.count } do
        result = Reroll.new(character, item_id: item.id, payment: "wen", rng: FixedRng.new(option_roll: 0.0, values: [ 30 ])).call

        assert_not result.success?
        assert_equal :payment_missing, result.error
      end

      assert_equal Reroll::WEN_COST - 1, character.reload.currency
      assert_equal [ { "key" => "power", "value" => 12 } ], item.reload.power_options
    end

    test "fails when item is not owned by character" do
      character = users(:one).character
      other_item = users(:two).character.create_inventory_item!(name: "iron_dao_blade", equipment_kind: "weapon", power_options: [])

      result = Reroll.new(character, item_id: other_item.id, payment: "wen").call

      assert_not result.success?
      assert_equal :item_missing, result.error
    end

    class FixedRng
      def initialize(option_roll:, values:)
        @option_roll = option_roll
        @values = values
      end

      def rand(argument = nil)
        return @option_roll unless argument

        @values.shift
      end
    end
  end
end
