module Shops
  class Sale
    WEN_VALUE = Purchase::WEN_COST / 2

    Result = Data.define(:success?, :item_name, :wen, :error)

    def initialize(character, inventory_item_id)
      @character = character
      @inventory_item_id = inventory_item_id
    end

    def call
      item = character.inventory_items.in_inventory.find_by(id: inventory_item_id)
      return failure(:item_unavailable) unless item

      item_name = item.localized_name
      ActiveRecord::Base.transaction do
        character.update!(currency: character.currency + WEN_VALUE)
        create_sale_event(item)
        item.destroy!
      end

      Result.new(success?: true, item_name:, wen: WEN_VALUE, error: nil)
    end

    private

    attr_reader :character, :inventory_item_id

    def failure(error)
      Result.new(success?: false, item_name: nil, wen: nil, error:)
    end

    def create_sale_event(item)
      character.game_events.create!(
        event_key: "shop_sale",
        outcome: "neutral",
        title: "shops.sale_event.title",
        description: "shops.sale_event.description",
        metadata: {
          "inventory_item_name_key" => item.name,
          "wen" => WEN_VALUE
        },
        qi_delta: 0,
        happened_at: Time.current
      )
    end
  end
end
