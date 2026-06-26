require "test_helper"

module InventoryItems
  class PowerRollTest < ActiveSupport::TestCase
    test "returns power and accuracy for weapons" do
      character = users(:one).character
      character.update!(realm: 1, star: 1)
      rng = FixedRng.new(values: [ 11, 2 ])

      power_options = PowerRoll.new(character, equipment_kind: "weapon", rng:).call

      assert_equal [ { "key" => "power", "value" => 11 }, { "key" => "accuracy", "value" => 2 } ], power_options
      assert_equal [ 8..14, 1.0..3.0 ], rng.ranges
    end

    test "scales power range by realm and star with overlapping steps" do
      character = users(:one).character
      expected_ranges = {
        1 => 8..14,
        2 => 11..18,
        3 => 14..23,
        4 => 18..29,
        5 => 22..36
      }

      expected_ranges.each do |star, expected_range|
        character.update!(realm: 1, star:)
        rng = FixedRng.new(values: [ expected_range.begin, 1 ])

        PowerRoll.new(character, equipment_kind: "weapon", rng:).call

        assert_equal expected_range, rng.ranges.first
      end
    end

    test "uses minimum power when calculated power is lower than minimum" do
      character = users(:one).character
      config = CultivationEvents::Registry.events.fetch(:found_equipment_item).merge(power_option_min: 200)
      rng = FixedRng.new(values: [ 200, 1 ])

      power_options = PowerRoll.new(character, equipment_kind: "weapon", config:, rng:).call

      assert_equal({ "key" => "power", "value" => 200 }, power_options.first)
      assert_equal 200..200, rng.ranges.first
    end

    test "returns two distinct random stats for rings and pendants" do
      character = users(:one).character
      allowed_keys = %w[ power health defense evasion accuracy critical_rate ]

      %w[ ring pendant ].each do |equipment_kind|
        power_options = PowerRoll.new(character, equipment_kind:, rng: Random.new(1)).call

        assert_equal 2, power_options.size
        assert_equal power_options.pluck("key").uniq, power_options.pluck("key")
        assert_empty power_options.pluck("key") - allowed_keys
      end
    end

    class FixedRng
      attr_reader :ranges

      def initialize(values:)
        @values = values
        @ranges = []
      end

      def rand(argument)
        @ranges << argument
        @values.shift
      end
    end
  end
end
