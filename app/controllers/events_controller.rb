class EventsController < ApplicationController
  EVENTS_PER_PAGE = 10

  def index
    @character = current_character
    @page = [ params[:page].to_i, 1 ].max
    events = @character.game_events.order(happened_at: :desc)
    @events = events.offset((@page - 1) * EVENTS_PER_PAGE).limit(EVENTS_PER_PAGE)
    @has_next_page = events.offset(@page * EVENTS_PER_PAGE).exists?
  end
end
