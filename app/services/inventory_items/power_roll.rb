module InventoryItems
  class PowerRoll
    def initialize(character, config: CultivationEvents::Registry.events.fetch(:found_equipment_item), rng: Random)
      @character = character
      @config = config
      @rng = rng
    end

    def call
      Array.new(random_option_count) do
        { "key" => "power", "value" => rng.rand(power_range) }
      end
    end

    private

    attr_reader :character, :config, :rng

    def power_range
      minimum = config.fetch(:power_option_min)
      minimum..[ character.power, minimum ].max
    end

    def random_option_count
      roll = rng.rand * 100
      total = 0

      config.fetch(:option_count_chances).each do |count, chance|
        total += chance
        return count if roll < total
      end

      1
    end
  end
end
