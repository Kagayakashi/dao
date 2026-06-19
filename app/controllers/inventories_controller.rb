class InventoriesController < ApplicationController
  def show
    @character = Current.user.character || Current.user.create_character!
  end
end
