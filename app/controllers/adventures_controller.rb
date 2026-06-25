class AdventuresController < ApplicationController
  def show
    @character = Current.user.character || Current.user.create_character!
    @character.recover_sparring_points!
  end
end
