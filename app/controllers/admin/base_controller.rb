module Admin
  class BaseController < ApplicationController
    allow_unauthenticated_access
    before_action :require_admin_authentication
    helper_method :character_options

    private

    def require_admin_authentication
      return if session[:admin_authenticated]

      redirect_to new_admin_session_path, alert: t("admin.sessions.required")
    end

    def character_options
      Character.order(:name).map { |character| [ character_option_label(character), character.id ] }
    end

    def character_option_label(character)
      t("admin.shared.character_option", name: character.name, realm: character.realm_name, star: character.star)
    end
  end
end
