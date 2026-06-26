module CombatStats
  class CharacterStats
    DEFAULT_CONFIG = {
      target_landed_hits: 15,
      defense_damage_ratio: 0.35,
      evasion_base: 20,
      evasion_step_bonus: 2,
      hit_chance_target: 80,
      critical_rate_base: 5,
      critical_rate_step_bonus: 0,
      maximum_critical_rate: 50
    }.freeze

    def initialize(character, config: Character.combat_stat_config)
      @character = character
      @config = DEFAULT_CONFIG.merge(config)
    end

    def damage
      character.power
    end

    def health
      ((equal_level_effective_damage * config.fetch(:target_landed_hits)) + equipment_bonus(:health)).round
    end

    def defense
      (base_defense + equipment_bonus(:defense)).round
    end

    def evasion
      (base_evasion + equipment_bonus(:evasion)).round(1)
    end

    def accuracy
      (base_accuracy + equipment_bonus(:accuracy)).round(1)
    end

    def critical_rate
      [
        config.fetch(:critical_rate_base) + (cultivation_step * config.fetch(:critical_rate_step_bonus)) + equipment_bonus(:critical_rate),
        config.fetch(:maximum_critical_rate)
      ].min.round(1)
    end

    def to_h
      {
        damage:,
        health:,
        defense:,
        evasion:,
        accuracy:,
        critical_rate:
      }
    end

    private

    attr_reader :character, :config

    def equal_level_effective_damage
      [ cultivation_damage - base_defense, 1 ].max
    end

    def base_defense
      cultivation_damage * config.fetch(:defense_damage_ratio)
    end

    def base_evasion
      config.fetch(:evasion_base) + (cultivation_step * config.fetch(:evasion_step_bonus))
    end

    def base_accuracy
      base_evasion + config.fetch(:hit_chance_target)
    end

    def equipment_bonus(stat_key)
      character.equipment_stat_bonus(stat_key)
    end

    def cultivation_damage
      character.cultivation_power
    end

    def cultivation_step
      ((character.realm - 1) * character.stars_per_realm) + (character.star - 1)
    end
  end
end
