module Admin
  class SessionsController < ApplicationController
    allow_unauthenticated_access
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
  end
end
