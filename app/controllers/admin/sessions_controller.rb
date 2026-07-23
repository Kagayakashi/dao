module Admin
  class SessionsController < ApplicationController
    allow_unauthenticated_access
    before_action :load_login_log, only: :new
    rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_admin_session_path, alert: t("shared.rate_limit") }

    def new
    end

    def create
      if CredentialPassword.authenticate?(params[:password])
        session[:admin_authenticated] = true
        redirect_to admin_root_path, notice: t("admin.sessions.create.notice")
      else
        redirect_to new_admin_session_path, alert: t("admin.sessions.create.invalid")
      end
    end

    def destroy
      session.delete(:admin_authenticated)
      redirect_to new_admin_session_path, status: :see_other, notice: t("admin.sessions.destroy.notice")
    end

    private
      def load_login_log
        game_session = Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]

        @login_log = {
          game_session: game_session,
          current_ip_address: request.remote_ip
        }
      end
  end
end
