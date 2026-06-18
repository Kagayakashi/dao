class PagesController < ApplicationController
  allow_unauthenticated_access only: :cookie_policy

  def cookie_policy
  end
end
