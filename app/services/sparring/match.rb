module Sparring
  class Match
    def self.win_chance(challenger:, opponent:)
      total_power = challenger.power + opponent.power
      return 0.5 if total_power <= 0

      challenger.power.to_f / total_power
    end

    def initialize(challenger:, opponent:, victory_qi_hours:, defeat_qi_hours:, rng: Random.new)
      @challenger = challenger
      @opponent = opponent
      @victory_qi_hours = victory_qi_hours
      @defeat_qi_hours = defeat_qi_hours
      @rng = rng
    end

    def call
      chance = challenger_win_chance
      won = rng.rand < chance

      {
        outcome: won ? "victory" : "defeat",
        reciprocal_outcome: won ? "defeat" : "victory",
        qi_delta: qi_for_hours(won ? victory_qi_hours : defeat_qi_hours),
        related_character: opponent,
        description: description_key(won),
        reciprocal_description: description_key(!won),
        metadata: {
          "challenger_win_chance" => chance.round(4),
          "opponent_win_chance" => (1.0 - chance).round(4)
        }
      }
    end

    private

    attr_reader :challenger, :opponent, :victory_qi_hours, :defeat_qi_hours, :rng

    def challenger_win_chance
      self.class.win_chance(challenger:, opponent:)
    end

    def description_key(won)
      return "sparring.matches.victory_description" if won

      "sparring.matches.defeat_description"
    end

    def qi_for_hours(hours)
      (Character.base_qi_per_second * hours.hours.to_i).floor
    end
  end
end
