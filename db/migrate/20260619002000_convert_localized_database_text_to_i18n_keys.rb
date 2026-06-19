class ConvertLocalizedDatabaseTextToI18nKeys < ActiveRecord::Migration[8.1]
  ITEM_NAME_KEYS_BY_KIND = {
    "weapon" => %w[ iron_dao_blade bamboo_spirit_sword ashen_spear ],
    "ring" => %w[ cloud_ring jade_band quiet_moon_ring ],
    "pendant" => %w[ old_dragon_pendant river_jade_pendant worn_spirit_charm ]
  }.freeze

  ITEM_NAME_TEXT_TO_KEY = {
    "Iron Dao Blade" => "iron_dao_blade",
    "Bamboo Spirit Sword" => "bamboo_spirit_sword",
    "Ashen Spear" => "ashen_spear",
    "Cloud Ring" => "cloud_ring",
    "Jade Band" => "jade_band",
    "Quiet Moon Ring" => "quiet_moon_ring",
    "Old Dragon Pendant" => "old_dragon_pendant",
    "River Jade Pendant" => "river_jade_pendant",
    "Worn Spirit Charm" => "worn_spirit_charm",
    "Железный клинок Дао" => "iron_dao_blade",
    "Бамбуковый духовный меч" => "bamboo_spirit_sword",
    "Пепельное копье" => "ashen_spear",
    "Облачное кольцо" => "cloud_ring",
    "Нефритовый обруч" => "jade_band",
    "Кольцо Тихой Луны" => "quiet_moon_ring",
    "Старая подвеска дракона" => "old_dragon_pendant",
    "Речная нефритовая подвеска" => "river_jade_pendant",
    "Потертый духовный оберег" => "worn_spirit_charm"
  }.freeze

  MYSTERIOUS_ITEM_TEXT_TO_KEY = {
    "Jade Pill" => "jade_pill",
    "Cracked Spirit Stone" => "cracked_spirit_stone",
    "Dusty Talisman" => "dusty_talisman",
    "Нефритовая пилюля" => "jade_pill",
    "Треснувший духовный камень" => "cracked_spirit_stone",
    "Пыльный талисман" => "dusty_talisman"
  }.freeze

  TITLE_KEYS = {
    "good_cultivation_place" => "cultivation_events.good_cultivation_place.title",
    "mysterious_item" => "cultivation_events.mysterious_item.title",
    "stranger_cultivator" => "cultivation_events.stranger_cultivator.title",
    "found_equipment_item" => "cultivation_events.found_equipment_item.title"
  }.freeze

  DESCRIPTION_KEYS = {
    [ "good_cultivation_place", "positive" ] => "cultivation_events.good_cultivation_place.description",
    [ "mysterious_item", "positive" ] => "cultivation_events.mysterious_item.positive_description",
    [ "mysterious_item", "negative" ] => "cultivation_events.mysterious_item.negative_description",
    [ "mysterious_item", "neutral" ] => "cultivation_events.mysterious_item.neutral_description",
    [ "stranger_cultivator", "peaceful" ] => "cultivation_events.stranger_cultivator.peaceful_description",
    [ "stranger_cultivator", "victory" ] => "cultivation_events.stranger_cultivator.victory_description",
    [ "stranger_cultivator", "defeat" ] => "cultivation_events.stranger_cultivator.defeat_description",
    [ "found_equipment_item", "positive" ] => "cultivation_events.found_equipment_item.description",
    [ "found_equipment_item", "full_inventory" ] => "cultivation_events.found_equipment_item.inventory_full_description"
  }.freeze

  def up
    convert_inventory_item_names
    convert_game_event_text
  end

  def down
    # Irreversible: converting locale-specific text to stable i18n keys discards the original locale.
  end

  private

  def convert_inventory_item_names
    inventory_item.find_each do |item|
      key = ITEM_NAME_TEXT_TO_KEY[item.name]
      next unless key

      item.update_columns(name: key)
    end
  end

  def convert_game_event_text
    game_event.find_each do |event|
      metadata = JSON.parse(event.metadata.presence || "{}")
      metadata = convert_event_metadata(event, metadata)

      updates = { metadata: JSON.generate(metadata) }
      updates[:title] = TITLE_KEYS.fetch(event.event_key, event.title)
      updates[:description] = DESCRIPTION_KEYS.fetch([ event.event_key, event.outcome ], event.description)

      event.update_columns(updates)
    end
  end

  def convert_event_metadata(event, metadata)
    case event.event_key
    when "mysterious_item"
      key = metadata.delete("item_name_key") || MYSTERIOUS_ITEM_TEXT_TO_KEY[metadata.delete("item_name")]
      key ? { "item_name_key" => key } : metadata
    when "found_equipment_item"
      key = metadata.delete("inventory_item_name_key") || inventory_item_key_from_metadata(metadata) || ITEM_NAME_TEXT_TO_KEY[metadata.delete("item_name")]
      key ? { "inventory_item_name_key" => key } : metadata
    when "stranger_cultivator"
      metadata.delete("name")
      metadata["name_i18n_key"] ||= "cultivation_events.stranger_cultivator.passing_cultivator" if event.related_character_id.blank?
      metadata
    else
      metadata
    end
  end

  def inventory_item_key_from_metadata(metadata)
    kind = metadata.delete("equipment_kind")
    index = metadata.delete("item_name_index")
    return unless kind.present? && index.present?

    ITEM_NAME_KEYS_BY_KIND.fetch(kind).fetch(index.to_i)
  end

  def inventory_item
    Class.new(ActiveRecord::Base) do
      self.table_name = "inventory_items"
    end
  end

  def game_event
    Class.new(ActiveRecord::Base) do
      self.table_name = "game_events"
    end
  end
end
