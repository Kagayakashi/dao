module Admin
  class DashboardController < BaseController
    before_action :load_login_log

    def show
    end

    private
      def load_login_log
        @admin_logins = AdminLogin.order(created_at: :desc).limit(5)
      end
  end
end
