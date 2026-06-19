class UsersController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(temporary_user_params)

    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: t("users.create.notice")
    else
      flash.now[:alert] = t("users.create.alert")
      render :new, status: :unprocessable_entity
    end
  end

  private

  def temporary_user_params
    permitted_params = params.require(:user).permit(:character_name, :character_gender)
    password = SecureRandom.urlsafe_base64(32)

    permitted_params.merge(
      email_address: "temporary-#{SecureRandom.uuid}@dao.local",
      password:,
      password_confirmation: password,
      temporary: true
    )
  end
end
