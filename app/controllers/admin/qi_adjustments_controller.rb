module Admin
  class QiAdjustmentsController < BaseController
    def new
    end

    def create
      character = Character.find(qi_adjustment_params.fetch(:character_id))
      amount = signed_amount
      character.admin_adjust_qi!(amount)

      redirect_to new_admin_qi_adjustment_path, notice: t(
        "admin.qi_adjustments.create.notice",
        qi: helpers.number_with_delimiter(amount.abs),
        direction: t("admin.qi_adjustments.create.directions.#{amount.negative? ? 'removed' : 'added'}"),
        character: character.name,
        realm: character.realm_name,
        star: character.star
      )
    end

    private

    def qi_adjustment_params
      params.require(:qi_adjustment).permit(:character_id, :direction, :amount)
    end

    def signed_amount
      amount = qi_adjustment_params.fetch(:amount).to_i.abs
      return -amount if qi_adjustment_params.fetch(:direction) == "remove"

      amount
    end
  end
end
