class CharactersController < ApplicationController
  def show
    @character = Character.includes(:character_achievements, :inventory_items).find(params[:id])
  end
end
