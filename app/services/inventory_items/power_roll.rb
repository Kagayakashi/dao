module InventoryItems
  class PowerRoll
    WEAPON_STAT_KEYS = %i[ power accuracy ].freeze
    ACCESSORY_STAT_KEYS = %i[ power health defense evasion accuracy critical_rate ].freeze

    def initialize(character, equipment_kind: nil, config: CultivationEvents::Registry.events.fetch(:found_equipment_item), rng: Random)
      @character = character
      @equipment_kind = equipment_kind
      @config = config
      @rng = rng
    end

    def call
      stat_keys.map { |stat_key| stat_roll(stat_key).call }
    end

    private

    attr_reader :character, :equipment_kind, :config, :rng

    def stat_roll(stat_key)
      StatRoll.new(character, stat_key:, config:, rng:)
    end

    def stat_keys
      return WEAPON_STAT_KEYS if equipment_kind == "weapon"

      ACCESSORY_STAT_KEYS.sample(2, random: rng)
    end
  end
end
