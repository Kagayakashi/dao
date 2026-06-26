class AdventuresController < ApplicationController
  def show
    @character = current_character
    @character.recover_sparring_points!
  end
end
