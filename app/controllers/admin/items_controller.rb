module Admin
  class ItemsController < BaseController
    helper_method :item_name_options

    def new
    end

    def create
      character = Character.find(item_params.fetch(:character_id))
      item_name_key = item_params.fetch(:name)
      item = character.create_inventory_item!(
        name: item_name_key,
        equipment_kind: equipment_kind_for(item_name_key),
        power_options: [ { "key" => "power", "value" => item_params.fetch(:power).to_i } ]
      )

      if item
        redirect_to new_admin_item_path, notice: t("admin.items.create.notice", name: item.localized_name, character: character.name)
      else
        redirect_to new_admin_item_path, alert: t("admin.items.create.inventory_full", character: character.name), status: :see_other
      end
    end

    private

    def item_params
      params.require(:inventory_item).permit(:character_id, :name, :power)
    end

    def item_name_options
      InventoryItem::EQUIPMENT_KINDS.flat_map do |kind|
        I18n.t("inventory_items.item_keys.#{kind}").map do |key|
          [ t("admin.items.new.item_option", kind: t("inventory_items.kinds.#{kind}"), name: t("inventory_items.names.#{key}")), key ]
        end
      end
    end

    def equipment_kind_for(item_name_key)
      InventoryItem::EQUIPMENT_KINDS.find do |kind|
        I18n.t("inventory_items.item_keys.#{kind}").include?(item_name_key)
      end
    end
  end
end
