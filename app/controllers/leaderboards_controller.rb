class LeaderboardsController < ApplicationController
  PER_PAGE = 20

  def show
    @page = [ params[:page].to_i, 1 ].max
    @total_count = Character.count
    @total_pages = [ (@total_count.to_f / PER_PAGE).ceil, 1 ].max
    @page = @total_pages if @page > @total_pages
    @rank_offset = (@page - 1) * PER_PAGE
    @characters = leaderboard_characters.limit(PER_PAGE).offset(@rank_offset)
  end

  private

  def leaderboard_characters
    Character.order(total_experience: :desc, level: :desc, sublevel: :desc, id: :asc)
  end
end
