class TemplesController < ApplicationController
  before_action :load_character

  def show
  end

  def pray
    gained_qi = @character.claim_daily_reward!

    flash[:notice] = if gained_qi
      t("temples.pray.notice.claimed", qi: helpers.number_with_delimiter(gained_qi))
    else
      t("temples.pray.notice.not_ready")
    end

    redirect_to temple_path, status: :see_other
  end

  private

  def load_character
    @character = current_character
  end
end
