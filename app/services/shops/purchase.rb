module Shops
  class Purchase
    WEN_COST = 300

    Result = Data.define(:success?, :item, :error)

    def initialize(character, rng: Random)
      @character = character
      @rng = rng
    end

    def call
      return failure(:inventory_full) if character.inventory_full?
      return failure(:payment_missing) if character.currency < WEN_COST

      equipment_kind = InventoryItem::EQUIPMENT_KINDS.sample(random: rng)
      item_name_key = I18n.t("inventory_items.item_keys.#{equipment_kind}").sample(random: rng)

      item = nil
      ActiveRecord::Base.transaction do
        character.update!(currency: character.currency - WEN_COST)
        item = character.create_inventory_item!(
          name: item_name_key,
          equipment_kind:,
          power_options: InventoryItems::PowerRoll.new(character, equipment_kind:, rng:).call,
          metadata: {}
        )
        create_purchase_event(item)
      end

      Result.new(success?: true, item:, error: nil)
    end

    private

    attr_reader :character, :rng

    def failure(error)
      Result.new(success?: false, item: nil, error:)
    end

    def create_purchase_event(item)
      character.game_events.create!(
        event_key: "shop_purchase",
        outcome: "positive",
        title: "shops.events.title",
        description: "shops.events.description",
        metadata: {
          "inventory_item_name_key" => item.name,
          "power_options" => item.power_options
        },
        qi_delta: 0,
        happened_at: Time.current
      )
    end
  end
end
