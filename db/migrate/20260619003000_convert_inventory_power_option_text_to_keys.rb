class ConvertInventoryPowerOptionTextToKeys < ActiveRecord::Migration[8.1]
  POWER_OPTION_TEXT_TO_KEY = {
    "Power" => "power",
    "Сила" => "power"
  }.freeze

  def up
    inventory_item.find_each do |item|
      power_options = JSON.parse(item.power_options.presence || "[]")
      converted_options = power_options.map { |option| convert_power_option(option) }
      item.update_columns(power_options: JSON.generate(converted_options))
    end
  end

  def down
    # Irreversible: converting locale-specific text to stable i18n keys discards the original locale.
  end

  private

  def convert_power_option(option)
    key = option.delete("key") || POWER_OPTION_TEXT_TO_KEY[option.delete("name")]
    key ? option.merge("key" => key) : option
  end

  def inventory_item
    Class.new(ActiveRecord::Base) do
      self.table_name = "inventory_items"
    end
  end
end
