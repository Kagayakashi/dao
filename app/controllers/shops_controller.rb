class ShopsController < ApplicationController
  def show
    load_character
  end

  def create
    load_character
    return redirect_to shop_path, alert: t("shops.create.alert.expedition_active"), status: :see_other if @character.spirit_expedition_active?

    result = Shops::Purchase.new(@character).call

    if result.success?
      redirect_to shop_path, notice: t("shops.create.notice.purchased", item: result.item.localized_name), status: :see_other
    else
      redirect_to shop_path, alert: t("shops.create.alert.#{result.error}"), status: :see_other
    end
  end

  private

  def load_character
    @character = current_character
  end
end
