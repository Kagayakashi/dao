module CultivationEvents
  module Registry
    DEFAULT_COOLDOWN = 30.minutes.to_i..1.hour.to_i
    GLOBAL_EVENT_KEY = "__random_event__"
    GLOBAL_EVENT_COOLDOWN = 1.hour.to_i..1.hour.to_i

    EVENTS = {
      good_cultivation_place: {
        cooldown: DEFAULT_COOLDOWN,
        qi_hours: 1
      },
      mysterious_item: {
        cooldown: DEFAULT_COOLDOWN,
        items: [
          { name_key: "jade_pill", outcome: :positive, qi_hours: 1 },
          { name_key: "cracked_spirit_stone", outcome: :negative, qi_hours: -3 },
          { name_key: "dusty_talisman", outcome: :neutral, qi_hours: 0 }
        ]
      },
      stranger_cultivator: {
        cooldown: DEFAULT_COOLDOWN,
        peaceful_qi_hours: 0,
        victory_qi_hours: 1,
        defeat_qi_hours: 0.5
      },
      found_equipment_item: {
        cooldown: 1.day.to_i..1.day.to_i,
        equipment_kinds: %w[ weapon ring pendant ]
      }
    }.freeze

    module_function

    def events
      EVENTS
    end

    def global_event_key
      GLOBAL_EVENT_KEY
    end

    def global_event_cooldown
      GLOBAL_EVENT_COOLDOWN
    end
  end
end
