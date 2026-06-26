require "test_helper"

class Sparring::MatchTest < ActiveSupport::TestCase
  setup do
    @challenger = characters(:one)
    @opponent = characters(:two)
    Character.base_qi_per_second = 1
  end

  test "returns victory when random roll is within challenger power chance" do
    @challenger.update!(realm: 2, star: 1)
    @opponent.update!(realm: 1, star: 1)

    result = Sparring::Match.new(challenger: @challenger, opponent: @opponent, victory_qi_hours: 1, defeat_qi_hours: -1, rng: fixed_rng(0.66)).call

    assert_equal "victory", result[:outcome]
    assert_equal "defeat", result[:reciprocal_outcome]
    assert_equal 3_600, result[:qi_delta]
    assert_equal @opponent, result[:related_character]
    assert_equal "sparring.matches.victory_description", result[:description]
    assert_equal({ "challenger_win_chance" => 0.6667, "opponent_win_chance" => 0.3333 }, result[:metadata])
  end

  test "returns defeat when random roll is above challenger power chance" do
    @challenger.update!(realm: 2, star: 1)
    @opponent.update!(realm: 1, star: 1)

    result = Sparring::Match.new(challenger: @challenger, opponent: @opponent, victory_qi_hours: 1, defeat_qi_hours: -1, rng: fixed_rng(0.67)).call

    assert_equal "defeat", result[:outcome]
    assert_equal(-3_600, result[:qi_delta])
    assert_equal "sparring.matches.defeat_description", result[:description]
  end

  test "calculates public win chance from power" do
    @challenger.update!(realm: 2, star: 1)
    @opponent.update!(realm: 1, star: 1)

    assert_equal 0.6667, Sparring::Match.win_chance(challenger: @challenger, opponent: @opponent).round(4)
  end

  private

  def fixed_rng(value)
    Struct.new(:value) do
      def rand
        value
      end
    end.new(value)
  end
end
