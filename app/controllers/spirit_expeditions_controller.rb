class SpiritExpeditionsController < ApplicationController
  def show
    load_character
    @completed_spirit_expedition = @character.complete_spirit_expedition! if @character.spirit_expedition_ends_at.present?
  end

  def create
    load_character

    if @character.start_spirit_expedition!(hours: params[:hours])
      redirect_to spirit_expedition_path, notice: t("spirit_expeditions.create.notice.started", hours: params[:hours].to_i), status: :see_other
    else
      redirect_to spirit_expedition_path, alert: t("spirit_expeditions.create.alert.unavailable"), status: :see_other
    end
  end

  def complete
    load_character
    result = @character.complete_spirit_expedition_now!

    if result
      redirect_to spirit_expedition_path, notice: t("spirit_expeditions.complete.notice.completed", qi: helpers.resource_amount_with_bonus(base: result[:base_qi], bonus: result[:qi_bonus]), wen: helpers.resource_amount_with_bonus(base: result[:base_wen], bonus: result[:wen_bonus]), donation_currency: helpers.number_with_delimiter(result[:donation_currency])), status: :see_other
    else
      redirect_to spirit_expedition_path, alert: t("spirit_expeditions.complete.alert.unavailable"), status: :see_other
    end
  end

  private

  def load_character
    @character = current_character
  end
end
