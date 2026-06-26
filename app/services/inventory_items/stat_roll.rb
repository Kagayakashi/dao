module InventoryItems
  class StatRoll
    DEFAULT_CONFIGS = {
      power: {
        base_minimum: 15,
        base_maximum: 25,
        step_maximum_multiplier: 1.08,
        step_minimum_overlap: 0.75,
        decimals: 0,
        minimum_config_key: :power_option_min
      },
      health: {
        base_minimum: 60,
        base_maximum: 120,
        step_maximum_multiplier: 1.08,
        step_minimum_overlap: 0.75,
        decimals: 0
      },
      defense: {
        base_minimum: 3,
        base_maximum: 6,
        step_maximum_multiplier: 1.08,
        step_minimum_overlap: 0.75,
        decimals: 1
      },
      evasion: {
        base_minimum: 0.3,
        base_maximum: 0.8,
        step_maximum_multiplier: 1.091,
        step_minimum_overlap: 0.75,
        decimals: 1
      },
      accuracy: {
        base_minimum: 1.0,
        base_maximum: 3.0,
        step_maximum_multiplier: 1.02,
        step_minimum_overlap: 0.75,
        decimals: 1
      },
      critical_rate: {
        base_minimum: 0.2,
        base_maximum: 0.6,
        step_maximum_multiplier: 1.072,
        step_minimum_overlap: 0.75,
        decimals: 1
      }
    }.freeze

    def initialize(character, stat_key:, config: {}, stat_configs: DEFAULT_CONFIGS, rng: Random)
      @character = character
      @stat_key = stat_key.to_sym
      @config = config
      @stat_configs = stat_configs
      @rng = rng
    end

    def call
      { "key" => stat_key.to_s, "value" => rolled_value }
    end

    def range
      minimum..maximum
    end

    private

    attr_reader :character, :stat_key, :config, :stat_configs, :rng

    def rolled_value
      round_value(rng.rand(range))
    end

    def minimum
      [ calculated_minimum, configured_minimum ].compact.max
    end

    def maximum
      [ calculated_maximum, minimum ].max
    end

    def calculated_minimum
      return stat_config.fetch(:base_minimum) if cultivation_step.zero?

      round_minimum(maximum_for_step(cultivation_step - 1) * stat_config.fetch(:step_minimum_overlap))
    end

    def calculated_maximum
      maximum_for_step(cultivation_step)
    end

    def maximum_for_step(step)
      round_value(stat_config.fetch(:base_maximum) * (stat_config.fetch(:step_maximum_multiplier)**step))
    end

    def configured_minimum
      key = stat_config[:minimum_config_key]
      return unless key

      config[key]
    end

    def stat_config
      stat_configs.fetch(stat_key)
    end

    def cultivation_step
      ((character.realm - 1) * character.stars_per_realm) + (character.star - 1)
    end

    def round_minimum(value)
      return value.ceil if decimals.zero?

      (value * decimal_scale).ceil / decimal_scale.to_f
    end

    def round_value(value)
      return value.round if decimals.zero?

      value.round(decimals)
    end

    def decimals
      stat_config.fetch(:decimals)
    end

    def decimal_scale
      10**decimals
    end
  end
end
