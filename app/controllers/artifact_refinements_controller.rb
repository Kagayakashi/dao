class ArtifactRefinementsController < ApplicationController
  WEN_COST = 300
  LIANG_COST = 1

  def show
    load_character
    @items = refinement_items
  end

  def reroll
    load_character
    item = @character.inventory_items.find_by(id: params[:item_id])
    return redirect_to artifact_refinement_path, alert: t("artifact_refinements.reroll.alert.item_missing"), status: :see_other unless item

    payment = params[:payment].to_s
    return redirect_to artifact_refinement_path, alert: t("artifact_refinements.reroll.alert.payment_missing"), status: :see_other unless can_pay?(payment)

    old_power = item.inventory_power
    power_options = InventoryItems::PowerRoll.new(@character).call
    new_power = power_options.sum { |option| option.fetch("value", 0).to_i }

    ActiveRecord::Base.transaction do
      pay!(payment)
      item.update!(power_options:)
      create_refinement_event(item, old_power:, new_power:)
    end

    redirect_to artifact_refinement_path, notice: t("artifact_refinements.reroll.notice.complete", item: item.localized_name), status: :see_other
  end

  private

  def load_character
    @character = Current.user.character || Current.user.create_character!
  end

  def refinement_items
    @character.inventory_items.order(Arel.sql("inventory_slot IS NULL"), :inventory_slot, :equipment_slot, :created_at)
  end

  def can_pay?(payment)
    case payment
    when "wen"
      @character.currency >= WEN_COST
    when "liang"
      @character.donation_currency >= LIANG_COST
    else
      false
    end
  end

  def pay!(payment)
    case payment
    when "wen"
      @character.decrement!(:currency, WEN_COST)
    when "liang"
      @character.decrement!(:donation_currency, LIANG_COST)
    end
  end

  def create_refinement_event(item, old_power:, new_power:)
    @character.game_events.create!(
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
