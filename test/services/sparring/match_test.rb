require "test_helper"

class Sparring::MatchTest < ActiveSupport::TestCase
  setup do
    @challenger = characters(:one)
    @opponent = characters(:two)
    @original_base_qi_per_second = Character.base_qi_per_second
    Character.base_qi_per_second = 1
    @challenger.update!(realm: 2, star: 1, current_health: nil, health_recovered_at: Time.current)
    @opponent.update!(realm: 1, star: 1, current_health: nil, health_recovered_at: Time.current)
  end

  teardown do
    Character.base_qi_per_second = @original_base_qi_per_second
  end

  test "returns victory when challenger reduces opponent to one health" do
    @opponent.update!(current_health: 10)

    result = Sparring::Match.new(challenger: @challenger, opponent: @opponent, victory_qi_hours: 1, defeat_qi_hours: 0.5, rng: SequenceRng.always(0.0, 0.99)).call

    assert_equal "victory", result[:outcome]
    assert_equal "defeat", result[:reciprocal_outcome]
    assert_equal 3_600, result[:qi_delta]
    assert_equal @opponent, result[:related_character]
    assert_equal "sparring.matches.victory_description", result[:description]
    assert_equal 1, @opponent.reload.current_health
    assert_operator result[:metadata].fetch("damage_done"), :>, 0
    assert_equal 1, result[:metadata].fetch("opponent_health_remaining")
  end

  test "returns defeat when opponent deals more damage after five attacks each" do
    @challenger.update!(realm: 1, star: 1)
    @opponent.update!(realm: 2, star: 1)

    result = Sparring::Match.new(challenger: @challenger, opponent: @opponent, victory_qi_hours: 1, defeat_qi_hours: 0.5, rng: SequenceRng.always(0.0, 0.99)).call

    assert_equal "defeat", result[:outcome]
    assert_equal 1_800, result[:qi_delta]
    assert_equal "sparring.matches.defeat_description", result[:description]
    assert_operator result[:metadata].fetch("damage_taken"), :>, result[:metadata].fetch("damage_done")
  end

  test "returns reciprocal metadata from opponent perspective" do
    result = Sparring::Match.new(challenger: @challenger, opponent: @opponent, victory_qi_hours: 1, defeat_qi_hours: 0.5, rng: SequenceRng.always(0.0, 0.99)).call

    assert_equal result[:metadata].fetch("damage_done"), result[:reciprocal_metadata].fetch("damage_taken")
    assert_equal result[:metadata].fetch("damage_taken"), result[:reciprocal_metadata].fetch("damage_done")
  end

  test "hit chance gives evasion build close to sixty percent evade against mixed accuracy" do
    attacker = Struct.new(:accuracy).new(165)
    defender = Struct.new(:evasion).new(96)
    match = Sparring::Match.new(challenger: @challenger, opponent: @opponent, victory_qi_hours: 1, defeat_qi_hours: 0.5)

    evade_chance = 100 - match.send(:hit_chance, attacker, defender)

    assert_in_delta 58, evade_chance, 1
  end

  test "accuracy build counters evasion build" do
    attacker = Struct.new(:accuracy).new(260)
    defender = Struct.new(:evasion).new(96)
    match = Sparring::Match.new(challenger: @challenger, opponent: @opponent, victory_qi_hours: 1, defeat_qi_hours: 0.5)

    evade_chance = 100 - match.send(:hit_chance, attacker, defender)

    assert_in_delta 37, evade_chance, 1
  end

  class SequenceRng
    def self.always(*values)
      new(values.cycle)
    end

    def initialize(values)
      @values = values.to_enum
    end

    def rand
      @values.next
    end
  end
end
