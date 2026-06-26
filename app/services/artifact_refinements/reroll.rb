module ArtifactRefinements
  class Reroll
    WEN_COST = 300
    LIANG_COST = 1

    Result = Data.define(:success?, :item, :error)

    def initialize(character, item_id:, payment:, rng: Random)
      @character = character
      @item_id = item_id
      @payment = payment.to_s
      @rng = rng
    end

    def call
      item = character.inventory_items.find_by(id: item_id)
      return failure(:item_missing) unless item
      return failure(:payment_missing) unless can_pay?

      old_power = item.inventory_power
      power_options = InventoryItems::PowerRoll.new(character, rng:).call
      new_power = power_options.sum { |option| option.fetch("value", 0).to_i }

      ActiveRecord::Base.transaction do
        pay!
        item.update!(power_options:)
        create_refinement_event(item, old_power:, new_power:)
      end

      Result.new(success?: true, item:, error: nil)
    end

    private

    attr_reader :character, :item_id, :payment, :rng

    def failure(error)
      Result.new(success?: false, item: nil, error:)
    end

    def can_pay?
      case payment
      when "wen"
        character.currency >= WEN_COST
      when "liang"
        character.donation_currency >= LIANG_COST
      else
        false
      end
    end

    def pay!
      case payment
      when "wen"
        character.update!(currency: character.currency - WEN_COST)
      when "liang"
        character.update!(donation_currency: character.donation_currency - LIANG_COST)
      end
    end

    def create_refinement_event(item, old_power:, new_power:)
      character.game_events.create!(
        event_key: "artifact_refinement",
        outcome: "neutral",
        title: "artifact_refinements.events.title",
        description: "artifact_refinements.events.description",
        metadata: {
          "inventory_item_name_key" => item.name,
          "old_power" => old_power,
          "new_power" => new_power
        },
        qi_delta: 0,
        happened_at: Time.current
      )
    end
  end
end
