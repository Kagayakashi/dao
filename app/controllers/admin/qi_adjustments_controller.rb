module Admin
  class QiAdjustmentsController < BaseController
    def new
    end

    def create
      character = Character.find(qi_adjustment_params.fetch(:character_id))
      amount = signed_amount
      resource = qi_adjustment_params.fetch(:resource)
      apply_adjustment(character, resource, amount)

      redirect_to new_admin_qi_adjustment_path, notice: t(
        "admin.qi_adjustments.create.notice",
        amount: helpers.number_with_delimiter(amount.abs),
        resource: t("admin.qi_adjustments.resources.#{resource}"),
        direction: t("admin.qi_adjustments.create.directions.#{amount.negative? ? 'removed' : 'added'}"),
        character: character.name,
        realm: character.realm_name,
        star: character.star
      )
    end

    private

    def qi_adjustment_params
      params.require(:qi_adjustment).permit(:character_id, :resource, :direction, :amount)
    end

    def signed_amount
      amount = qi_adjustment_params.fetch(:amount).to_i.abs
      return -amount if qi_adjustment_params.fetch(:direction) == "remove"

      amount
    end

    def apply_adjustment(character, resource, amount)
      case resource
      when "qi"
        character.admin_adjust_qi!(amount)
      when "wen"
        character.update!(currency: [ character.currency + amount, 0 ].max)
      when "liang"
        character.update!(donation_currency: [ character.donation_currency + amount, 0 ].max)
      end
    end
  end
end
