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
      create_related_stranger_event(result) if event_key == :stranger_cultivator
      set_related_sparring_cooldown(result) if event_key == :stranger_cultivator
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
        description: "cultivation_events.good_cultivation_place.description"
      }
    end

    def mysterious_item_result(config)
      item = forced_item || config.fetch(:items).sample(random: rng)
      qi_delta = qi_for_hours(item.fetch(:qi_hours))

      {
        outcome: item.fetch(:outcome).to_s,
        qi_delta:,
        description: mysterious_item_description_key(qi_delta),
        metadata: mysterious_item_metadata(item)
      }
    end

    def stranger_cultivator_result(config)
      outcome = forced_outcome || [ :peaceful, :fight ].sample(random: rng)
      opponent = Character.available_for_sparring(now).where.not(id: character.id).order("RANDOM()").first

      return peaceful_stranger_result(config, opponent) if outcome == :peaceful || opponent.nil?

      fight_result(config, opponent)
    end

    def peaceful_stranger_result(config, opponent)
      qi_delta = qi_for_hours(config.fetch(:peaceful_qi_hours))

      {
        outcome: "peaceful",
        qi_delta:,
        related_character: opponent,
        description: "cultivation_events.stranger_cultivator.peaceful_description",
        metadata: stranger_metadata(opponent)
      }
    end

    def fight_result(config, opponent)
      result = Sparring::Match.new(
        challenger: character,
        opponent:,
        victory_qi_hours: config.fetch(:victory_qi_hours),
        defeat_qi_hours: config.fetch(:defeat_qi_hours),
        rng:
      ).call

      result.merge(description: stranger_fight_description(result.fetch(:outcome)))
    end

    def found_equipment_item_result(config)
      item_result = create_inventory_item(config)

      return inventory_full_result unless item_result

      {
        outcome: "positive",
        qi_delta: 0,
        description: "cultivation_events.found_equipment_item.description",
        metadata: item_result.fetch(:metadata)
      }
    end

    def create_inventory_item(config)
      equipment_kind = config.fetch(:equipment_kinds).sample(random: rng)
      item_name_key = I18n.t("inventory_items.item_keys.#{equipment_kind}").sample(random: rng)

      item = character.create_inventory_item!(
        name: item_name_key,
        equipment_kind:,
        power_options: power_options(config),
        metadata: {}
      )
      return false unless item

      { metadata: { "inventory_item_name_key" => item_name_key } }
    end

    def power_options(config)
      Array.new(random_option_count(config)) do
        { "key" => "power", "value" => rng.rand(config.fetch(:power_option_min)..[ character.power, config.fetch(:power_option_min) ].max) }
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
        description: "cultivation_events.found_equipment_item.inventory_full_description"
      }
    end

    def mysterious_item_description_key(qi_delta)
      return "cultivation_events.mysterious_item.neutral_description" if qi_delta.zero?
      return "cultivation_events.mysterious_item.positive_description" if qi_delta.positive?

      "cultivation_events.mysterious_item.negative_description"
    end

    def mysterious_item_metadata(item)
      return { "item_name_key" => item.fetch(:name_key).to_s } if item.key?(:name_key)

      { "item_name_key" => item.fetch(:name).to_s }
    end

    def stranger_fight_description(outcome)
      return "cultivation_events.stranger_cultivator.victory_description" if outcome == "victory"

      "cultivation_events.stranger_cultivator.defeat_description"
    end

    def stranger_metadata(opponent)
      return {} if opponent

      { "name_i18n_key" => "cultivation_events.stranger_cultivator.passing_cultivator" }
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
        title: "cultivation_events.#{event_key}.title",
        description: result.fetch(:description),
        metadata: result[:metadata] || {},
        qi_delta: result.fetch(:qi_delta),
        related_character: result[:related_character],
        happened_at: now
      )
    end

    def create_related_stranger_event(result)
      related_character = result[:related_character]
      return unless related_character

      related_character.game_events.create!(
        event_key: "stranger_cultivator",
        outcome: related_stranger_outcome(result.fetch(:outcome)),
        title: "cultivation_events.stranger_cultivator.title",
        description: related_stranger_description(result.fetch(:outcome)),
        metadata: {},
        qi_delta: 0,
        related_character: character,
        happened_at: now
      )
    end

    def set_related_sparring_cooldown(result)
      return unless %w[victory defeat].include?(result.fetch(:outcome))

      result.fetch(:related_character)&.mark_sparring_unavailable!(at: now)
    end

    def related_stranger_outcome(outcome)
      case outcome
      when "victory"
        "defeat"
      when "defeat"
        "victory"
      else
        outcome
      end
    end

    def related_stranger_description(outcome)
      case related_stranger_outcome(outcome)
      when "victory"
        "cultivation_events.stranger_cultivator.victory_description"
      when "defeat"
        "cultivation_events.stranger_cultivator.defeat_description"
      else
        "cultivation_events.stranger_cultivator.peaceful_description"
      end
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
