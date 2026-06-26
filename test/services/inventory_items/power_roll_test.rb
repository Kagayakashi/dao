require "test_helper"

module InventoryItems
  class PowerRollTest < ActiveSupport::TestCase
    test "returns random power options using item drop tuning" do
      character = users(:one).character
      character.update!(realm: 1, star: 1)
      rng = FixedRng.new(option_roll: 0.52, values: [ 11, 12 ])

      power_options = PowerRoll.new(character, rng:).call

      assert_equal [ { "key" => "power", "value" => 11 }, { "key" => "power", "value" => 12 } ], power_options
    end

    test "uses minimum power when character power is lower than minimum" do
      character = users(:one).character
      config = CultivationEvents::Registry.events.fetch(:found_equipment_item).merge(power_option_min: 200)
      rng = FixedRng.new(option_roll: 0.0, values: [ 200 ])

      power_options = PowerRoll.new(character, config:, rng:).call

      assert_equal [ { "key" => "power", "value" => 200 } ], power_options
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
