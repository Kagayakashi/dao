class SparringController < ApplicationController
  before_action :load_character

  def show
    @opponent = current_opponent
  end

  def create
    opponent = current_opponent
    return redirect_to sparring_path, alert: t("sparring.create.no_opponent"), status: :see_other unless opponent
    return redirect_to sparring_path, alert: t("sparring.create.opponent_resting"), status: :see_other unless opponent.available_for_sparring?

    unless @character.spend_sparring_point!
      return redirect_to sparring_path, alert: t("sparring.create.no_points"), status: :see_other
    end

    result = Sparring::Match.new(
      challenger: @character,
      opponent:,
      victory_qi_hours: 1,
      defeat_qi_hours: -1
    ).call
    @character.apply_qi_delta!(result.fetch(:qi_delta))
    @event = create_event(result)
    create_related_event(result)
    opponent.mark_sparring_unavailable!
    session.delete(:sparring_opponent_id)

    redirect_to sparring_path(result_event_id: @event.id), status: :see_other
  end

  def change_opponent
    new_opponent = random_opponent
    return redirect_to sparring_path, alert: t("sparring.change_opponent.no_opponent"), status: :see_other unless new_opponent

    unless @character.spend_sparring_point!
      return redirect_to sparring_path, alert: t("sparring.change_opponent.no_points"), status: :see_other
    end

    session[:sparring_opponent_id] = new_opponent.id
    redirect_to sparring_path, notice: t("sparring.change_opponent.notice"), status: :see_other
  end

  private

  def load_character
    @character = current_character
    @character.recover_sparring_points!
  end

  def current_opponent
    opponent = sparring_opponents.find_by(id: session[:sparring_opponent_id]) if session[:sparring_opponent_id]
    opponent ||= random_opponent
    session[:sparring_opponent_id] = opponent.id if opponent
    opponent
  end

  def random_opponent
    sparring_opponents.order("RANDOM()").first
  end

  def sparring_opponents
    Character.available_for_sparring.where.not(id: @character.id)
  end

  def create_event(result)
    @character.game_events.create!(
      event_key: "manual_sparring",
      outcome: result.fetch(:outcome),
      title: "sparring.matches.title",
      description: result.fetch(:description),
      metadata: result.fetch(:metadata),
      qi_delta: result.fetch(:qi_delta),
      related_character: result.fetch(:related_character),
      happened_at: Time.current
    )
  end

  def create_related_event(result)
    result.fetch(:related_character).game_events.create!(
      event_key: "manual_sparring",
      outcome: result.fetch(:reciprocal_outcome),
      title: "sparring.matches.title",
      description: result.fetch(:reciprocal_description),
      metadata: reciprocal_metadata(result.fetch(:metadata)),
      qi_delta: 0,
      related_character: @character,
      happened_at: Time.current
    )
  end

  def reciprocal_metadata(metadata)
    {
      "challenger_win_chance" => metadata.fetch("opponent_win_chance"),
      "opponent_win_chance" => metadata.fetch("challenger_win_chance")
    }
  end
end
