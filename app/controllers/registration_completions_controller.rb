class RegistrationCompletionsController < ApplicationController
  def new
    redirect_to character_path(Current.user.character), notice: t("registration_completions.already_complete") unless Current.user.temporary?
  end

  def create
    if Current.user.temporary?
      Current.user.complete_registration!(**registration_completion_params.to_h.symbolize_keys)
      redirect_to character_path(Current.user.character), notice: t("registration_completions.create.notice", qi: helpers.number_with_delimiter(User::COMPLETION_REWARD_QI))
    else
      redirect_to character_path(Current.user.character), notice: t("registration_completions.already_complete")
    end
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = t("registration_completions.create.alert")
    render :new, status: :unprocessable_entity
  end

  private

  def registration_completion_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
