class CultivationController < ApplicationController
  def show
    load_cultivation
  end

  def panel
    load_cultivation
    render partial: "panel", locals: { character: @character, offline_qi_gained: @offline_qi_gained, triggered_event: @triggered_event }
  end

  def breakthrough
    character = Current.user.character || Current.user.create_character!
    character.cultivate_offline!
    result = character.breakthrough!
    flash[:notice] = breakthrough_notice(result) if result
    redirect_to root_path, status: :see_other
  end

  private

  def load_cultivation
    @character = Current.user.character || Current.user.create_character!
    @offline_qi_gained = @character.cultivate_offline!
    @triggered_event = CultivationEvents::Runner.new(@character).call
  end

  def breakthrough_notice(result)
    return t("cultivation.breakthrough.notice.complete") if result[:lost_qi].zero?

    t("cultivation.breakthrough.notice.unstable_qi_dispersed", qi: helpers.number_with_delimiter(result[:lost_qi]))
  end
end
