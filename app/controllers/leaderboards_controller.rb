class LeaderboardsController < ApplicationController
  def show
    @characters = Character.includes(:user).order(total_experience: :desc, level: :desc, sublevel: :desc).limit(10)
  end
end
