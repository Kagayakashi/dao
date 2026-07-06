module Sparring
  class Match
    MAX_ATTACKS_PER_CHARACTER = 5
    MINIMUM_HEALTH = 1
    MINIMUM_HIT_CHANCE = 5
    MAXIMUM_HIT_CHANCE = 95
    DEFENSE_EFFECTIVENESS = 100.0
    CRITICAL_MULTIPLIER = 1.5

    def initialize(challenger:, opponent:, victory_qi_hours:, defeat_qi_hours:, rng: Random.new)
      @challenger = challenger
      @opponent = opponent
      @victory_qi_hours = victory_qi_hours
      @defeat_qi_hours = defeat_qi_hours
      @rng = rng
      @damage_done = { challenger => 0, opponent => 0 }
      @combat_log = []
      @health_remaining = {
        challenger => challenger.current_health_points,
        opponent => opponent.current_health_points
      }
    end

    def call
      challenger.recover_health!
      opponent.recover_health!
      refresh_health_remaining!
      winner = resolve_winner
      challenger_won = winner == challenger
      persist_health!

      qi_reward = challenger.qi_reward_breakdown(qi_for_hours(challenger_won ? victory_qi_hours : defeat_qi_hours))

      {
        outcome: challenger_won ? "victory" : "defeat",
        reciprocal_outcome: challenger_won ? "defeat" : "victory",
        qi_delta: qi_reward.fetch(:total),
        related_character: opponent,
        description: description_key(challenger_won),
        reciprocal_description: description_key(!challenger_won),
        metadata: metadata_for(challenger, opponent).merge(reward_metadata(qi_reward)),
        reciprocal_metadata: metadata_for(opponent, challenger)
      }
    end

    private

    attr_reader :challenger, :opponent, :victory_qi_hours, :defeat_qi_hours, :rng, :damage_done, :combat_log, :health_remaining

    def resolve_winner
      MAX_ATTACKS_PER_CHARACTER.times do
        attack(challenger, opponent)
        return challenger if defeated?(opponent)

        attack(opponent, challenger)
        return opponent if defeated?(challenger)
      end

      return challenger if damage_done.fetch(challenger) >= damage_done.fetch(opponent)

      opponent
    end

    def refresh_health_remaining!
      health_remaining[challenger] = challenger.current_health_points
      health_remaining[opponent] = opponent.current_health_points
    end

    def attack(attacker, defender)
      unless hit?(attacker, defender)
        combat_log << combat_log_entry(attacker, "miss", 0)
        return
      end

      critical = critical_hit?(attacker)
      damage = attack_damage(attacker, defender, critical:)
      damage_done[attacker] += damage
      health_remaining[defender] = [ health_remaining.fetch(defender) - damage, MINIMUM_HEALTH ].max
      combat_log << combat_log_entry(attacker, critical ? "critical" : "hit", damage)
    end

    def hit?(attacker, defender)
      rng.rand < (hit_chance(attacker, defender) / 100.0)
    end

    def attack_damage(attacker, defender, critical:)
      damage = [ reduced_damage(attacker.damage, defender.defense), attacker.damage * 0.1, 1 ].max
      damage *= CRITICAL_MULTIPLIER if critical
      damage.round
    end

    def critical_hit?(attacker)
      rng.rand < (attacker.critical_rate / 100.0)
    end

    def hit_chance(attacker, defender)
      return MINIMUM_HIT_CHANCE if attacker.accuracy <= 0

      (100 - ((defender.evasion.to_f / attacker.accuracy) * 100)).clamp(MINIMUM_HIT_CHANCE, MAXIMUM_HIT_CHANCE)
    end

    def reduced_damage(damage, defense)
      damage * (DEFENSE_EFFECTIVENESS / (DEFENSE_EFFECTIVENESS + defense))
    end

    def defeated?(character)
      health_remaining.fetch(character) <= MINIMUM_HEALTH
    end

    def persist_health!
      challenger.update!(current_health: health_remaining.fetch(challenger))
      opponent.update!(current_health: health_remaining.fetch(opponent))
    end

    def metadata_for(owner, rival)
      {
        "damage_done" => damage_done.fetch(owner),
        "damage_taken" => damage_done.fetch(rival),
        "health_remaining" => health_remaining.fetch(owner),
        "opponent_health_remaining" => health_remaining.fetch(rival),
        "combat_log" => combat_log_for(owner, rival)
      }
    end

    def reward_metadata(qi_reward)
      return {} if qi_reward.fetch(:total).zero?

      { "qi" => qi_reward.fetch(:total), "base_qi" => qi_reward.fetch(:base), "qi_bonus" => qi_reward.fetch(:bonus) }
    end

    def combat_log_entry(attacker, result, damage)
      {
        "actor" => attacker == challenger ? "challenger" : "opponent",
        "result" => result,
        "damage" => damage
      }
    end

    def combat_log_for(owner, rival)
      combat_log.map do |entry|
        entry.merge("actor" => combat_log_actor(entry.fetch("actor"), owner, rival))
      end
    end

    def combat_log_actor(actor, owner, rival)
      actor_character = actor == "challenger" ? challenger : opponent
      return "you" if actor_character == owner
      return "opponent" if actor_character == rival

      "opponent"
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
