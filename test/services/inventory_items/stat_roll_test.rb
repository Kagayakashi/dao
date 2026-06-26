require "test_helper"

module InventoryItems
  class StatRollTest < ActiveSupport::TestCase
    test "rolls requested integer stat from configured progression range" do
      character = users(:one).character
      character.update!(realm: 1, star: 5)
      rng = FixedRng.new(30)

      stat_option = StatRoll.new(character, stat_key: :health, rng:).call

      assert_equal({ "key" => "health", "value" => 30 }, stat_option)
      assert_equal 114..163, rng.range
    end

    test "rolls requested decimal stat from configured progression range" do
      character = users(:one).character
      character.update!(realm: 1, star: 5)
      rng = FixedRng.new(4.8)

      stat_option = StatRoll.new(character, stat_key: :defense, rng:).call

      assert_equal({ "key" => "defense", "value" => 4.8 }, stat_option)
      assert_equal 5.7..8.2, rng.range
    end

    test "allows stat configuration overrides" do
      character = users(:one).character
      character.update!(realm: 1, star: 1)
      rng = FixedRng.new(99)
      stat_configs = StatRoll::DEFAULT_CONFIGS.deep_merge(power: { base_minimum: 90, base_maximum: 100 })

      stat_option = StatRoll.new(character, stat_key: :power, stat_configs:, rng:).call

      assert_equal({ "key" => "power", "value" => 99 }, stat_option)
      assert_equal 90..100, rng.range
    end

    class FixedRng
      attr_reader :range

      def initialize(value)
        @value = value
      end

      def rand(range)
        @range = range
        @value
      end
    end
  end
end
