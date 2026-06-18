module CultivationEvents
  class Runner
    def initialize(character, now: Time.current, rng: Random.new, forced_event_key: nil, forced_outcome: nil, forced_item: nil)
      @character = character
      @now = now
      @rng = rng
      @forced_event_key = forced_event_key&.to_sym
      @forced_outcome = forced_outcome&.to_sym
      @forced_item = forced_item
    end

    def call
      return unless global_event_due?

      event_key = choose_event_key
      return unless event_key

      config = Registry.events.fetch(event_key)
      result = build_result(event_key, config)
      apply_qi_delta(result[:qi_delta])
      event = create_event(event_key, config, result)
      set_cooldown(event_key, config)
      set_global_cooldown
      event
    end

    private

    attr_reader :character, :now, :rng, :forced_event_key, :forced_outcome, :forced_item

    def choose_event_key
      available = available_event_keys
      return forced_event_key if forced_event_key && available.include?(forced_event_key)
      return if forced_event_key

      available.sample(random: rng)
    end

    def global_event_due?
      cooldown = character.character_event_cooldowns.find_by(event_key: Registry.global_event_key)

      cooldown.nil? || cooldown.next_event_at <= now
    end

    def available_event_keys
      Registry.events.keys.select do |event_key|
        cooldown = character.character_event_cooldowns.find_by(event_key: event_key.to_s)
        cooldown.nil? || cooldown.next_event_at <= now
      end
    end

    def build_result(event_key, config)
      case event_key
      when :good_cultivation_place
        good_cultivation_place_result(config)
      when :mysterious_item
        mysterious_item_result(config)
      when :stranger_cultivator
        stranger_cultivator_result(config)
      when :found_equipment_item
        found_equipment_item_result(config)
      end
    end

    def good_cultivation_place_result(config)
      qi_delta = qi_for_hours(config.fetch(:qi_hours))

      {
        outcome: "positive",
        qi_delta:,
        description: I18n.t("cultivation_events.good_cultivation_place.description")
      }
    end

    def mysterious_item_result(config)
      item = forced_item || config.fetch(:items).sample(random: rng)
      qi_delta = qi_for_hours(item.fetch(:qi_hours))

      {
        outcome: item.fetch(:outcome).to_s,
        qi_delta:,
        description: mysterious_item_description(item, qi_delta)
      }
    end

    def stranger_cultivator_result(config)
      outcome = forced_outcome || [ :peaceful, :fight ].sample(random: rng)
      opponent = Character.where.not(id: character.id).order("RANDOM()").first

      return peaceful_stranger_result(config, opponent) if outcome == :peaceful || opponent.nil?

      fight_result(config, opponent)
    end

    def peaceful_stranger_result(config, opponent)
      name = opponent&.name || I18n.t("cultivation_events.stranger_cultivator.passing_cultivator")
      qi_delta = qi_for_hours(config.fetch(:peaceful_qi_hours))

      {
        outcome: "peaceful",
        qi_delta:,
        related_character: opponent,
        description: I18n.t("cultivation_events.stranger_cultivator.peaceful_description", name:)
      }
    end

    def fight_result(config, opponent)
      won = character.power >= opponent.power
      qi_delta = qi_for_hours(won ? config.fetch(:victory_qi_hours) : config.fetch(:defeat_qi_hours))

      {
        outcome: won ? "victory" : "defeat",
        qi_delta:,
        related_character: opponent,
        description: fight_description(opponent, won)
      }
    end

    def found_equipment_item_result(config)
      item = create_inventory_item(config)

      return inventory_full_result unless item

      {
        outcome: "positive",
        qi_delta: 0,
        description: I18n.t("cultivation_events.found_equipment_item.description", item_name: item.name)
      }
    end

    def create_inventory_item(config)
      equipment_kind = config.fetch(:equipment_kinds).sample(random: rng)
      name = I18n.t("inventory_items.names.#{equipment_kind}").sample(random: rng)

      character.create_inventory_item!(
        name:,
        equipment_kind:,
        power_options: power_options(config)
      )
    end

    def power_options(config)
      Array.new(random_option_count(config)) do
        { "name" => I18n.t("inventory_items.power_options.power"), "value" => rng.rand(config.fetch(:power_option_min)..[ character.power, config.fetch(:power_option_min) ].max) }
      end
    end

    def random_option_count(config)
      roll = rng.rand * 100
      total = 0

      config.fetch(:option_count_chances).each do |count, chance|
        total += chance
        return count if roll < total
      end

      1
    end

    def inventory_full_result
      {
        outcome: "full_inventory",
        qi_delta: 0,
        description: I18n.t("cultivation_events.found_equipment_item.inventory_full_description")
      }
    end

    def mysterious_item_description(item, qi_delta)
      name = item_name(item)
      return I18n.t("cultivation_events.mysterious_item.neutral_description", item_name: name) if qi_delta.zero?
      return I18n.t("cultivation_events.mysterious_item.positive_description", item_name: name) if qi_delta.positive?

      I18n.t("cultivation_events.mysterious_item.negative_description", item_name: name)
    end

    def fight_description(opponent, won)
      return I18n.t("cultivation_events.stranger_cultivator.victory_description", name: opponent.name) if won

      I18n.t("cultivation_events.stranger_cultivator.defeat_description", name: opponent.name)
    end

    def item_name(item)
      return item.fetch(:name) if item.key?(:name)

      I18n.t("cultivation_events.mysterious_item.items.#{item.fetch(:name_key)}")
    end

    def apply_qi_delta(qi_delta)
      if qi_delta.positive?
        character.gain_qi(qi_delta)
        character.save!
        return
      end

      return if qi_delta.zero?

      character.qi = [ character.qi + qi_delta, 0 ].max
      character.save!
    end

    def create_event(event_key, config, result)
      character.game_events.create!(
        event_key: event_key.to_s,
        outcome: result.fetch(:outcome),
        title: I18n.t("cultivation_events.#{event_key}.title"),
        description: result.fetch(:description),
        qi_delta: result.fetch(:qi_delta),
        related_character: result[:related_character],
        happened_at: now
      )
    end

    def set_cooldown(event_key, config)
      cooldown = character.character_event_cooldowns.find_or_initialize_by(event_key: event_key.to_s)
      cooldown.next_event_at = now + rng.rand(config.fetch(:cooldown)).seconds
      cooldown.save!
    end

    def set_global_cooldown
      cooldown = character.character_event_cooldowns.find_or_initialize_by(event_key: Registry.global_event_key)
      cooldown.next_event_at = now + rng.rand(Registry.global_event_cooldown).seconds
      cooldown.save!
    end

    def qi_for_hours(hours)
      (Character.base_qi_per_second * hours.hours.to_i).floor
    end
  end
end
