class CultivationController < ApplicationController
  def show
    load_cultivation
  end

  def panel
    load_cultivation
    render partial: "panel", locals: { character: @character, offline_qi_gained: @offline_qi_gained, triggered_event: @triggered_event, completed_spirit_expedition: @completed_spirit_expedition }
  end

  def breakthrough
    character = current_character
    character.complete_spirit_expedition! if character.spirit_expedition_ends_at.present?
    character.cultivate_offline!
    result = character.breakthrough!
    flash[:notice] = breakthrough_notice(result) if result
    redirect_to root_path, status: :see_other
  end

  private

  def load_cultivation
    @character = current_character
    @completed_spirit_expedition = @character.complete_spirit_expedition! if @character.spirit_expedition_ends_at.present?
    @offline_qi_gained = @character.cultivate_offline!
    @character.recover_sparring_points!
    @triggered_event = CultivationEvents::Runner.new(@character).call unless @character.spirit_expedition_active?
  end

  def breakthrough_notice(result)
    return t("cultivation.breakthrough.notice.complete") if result[:lost_qi].zero?

    t("cultivation.breakthrough.notice.unstable_qi_dispersed", qi: helpers.number_with_delimiter(result[:lost_qi]))
  end
end
