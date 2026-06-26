require "test_helper"

module InventoryItems
  class PowerRollTest < ActiveSupport::TestCase
    test "returns power and accuracy for weapons" do
      character = users(:one).character
      character.update!(realm: 1, star: 1)
      rng = FixedRng.new(values: [ 20, 2 ])

      power_options = PowerRoll.new(character, equipment_kind: "weapon", rng:).call

      assert_equal [ { "key" => "power", "value" => 20 }, { "key" => "accuracy", "value" => 2 } ], power_options
      assert_equal [ 15..25, 1.0..3.0 ], rng.ranges
    end

    test "scales power range by realm and star with overlapping steps" do
      character = users(:one).character
      expected_ranges = {
        1 => 15..25,
        2 => 19..27,
        3 => 21..29,
        4 => 22..31,
        5 => 24..34
      }

      expected_ranges.each do |star, expected_range|
        character.update!(realm: 1, star:)
        rng = FixedRng.new(values: [ expected_range.begin, 1 ])

        PowerRoll.new(character, equipment_kind: "weapon", rng:).call

        assert_equal expected_range, rng.ranges.first
      end
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
