class InventoriesController < ApplicationController
  def show
    @character = current_character
  end
end
