class ArtifactRefinementsController < ApplicationController
  def show
    load_character
    @items = refinement_items
  end

  def reroll
    load_character
    return redirect_to artifact_refinement_path, alert: t("artifact_refinements.reroll.alert.expedition_active"), status: :see_other if @character.spirit_expedition_active?

    result = ArtifactRefinements::Reroll.new(@character, item_id: params[:item_id], payment: params[:payment]).call

    if result.success?
      redirect_to artifact_refinement_path, notice: t("artifact_refinements.reroll.notice.complete", item: result.item.localized_name), status: :see_other
    else
      redirect_to artifact_refinement_path, alert: t("artifact_refinements.reroll.alert.#{result.error}"), status: :see_other
    end
  end

  private

  def load_character
    @character = current_character
  end

  def refinement_items
    @character.inventory_items.order(Arel.sql("inventory_slot IS NULL"), :inventory_slot, :equipment_slot, :created_at)
  end
end
