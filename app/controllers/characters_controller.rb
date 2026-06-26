class CharactersController < ApplicationController
  def show
    @viewer_character = current_character
    @viewer_character.recover_health!
    @viewer_character.recover_sparring_points!
    @character = Character.includes(:character_achievements, :inventory_items).find(params[:id])
  end
end
