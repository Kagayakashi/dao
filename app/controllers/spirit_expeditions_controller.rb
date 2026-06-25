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

  private

  def load_character
    @character = Current.user.character || Current.user.create_character!
  end
end
