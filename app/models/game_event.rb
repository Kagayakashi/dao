class GameEvent < ApplicationRecord
  belongs_to :character
  belongs_to :related_character, class_name: "Character", optional: true

  serialize :metadata, coder: JSON

  validates :event_key, :outcome, :title, :description, :happened_at, presence: true
  validates :qi_delta, numericality: { only_integer: true }

  def localized_title
    localized_text(title)
  end

  def localized_description
    localized_text(description, **localized_metadata).tap do |text|
      return missing_item_description if text.include?("%{item_name}")
    end
  end

  private

  def localized_text(value, **options)
    return value unless value.start_with?("cultivation_events.")

    I18n.t(value, **options.symbolize_keys, default: value)
  end

  def localized_metadata
    metadata.to_h
      .merge("item_name" => localized_item_name, "name" => localized_name)
      .compact
      .symbolize_keys
  end

  def localized_name
    return related_character.name if related_character.present?
    return I18n.t(metadata["name_i18n_key"]) if metadata["name_i18n_key"].present?
    return I18n.t("cultivation_events.stranger_cultivator.passing_cultivator") if event_key == "stranger_cultivator"

    nil
  end

  def localized_item_name
    return I18n.t("cultivation_events.mysterious_item.items.#{metadata['item_name_key']}") if metadata["item_name_key"].present?
    return I18n.t("inventory_items.names.#{metadata['inventory_item_name_key']}") if metadata["inventory_item_name_key"].present?

    nil
  end

  def missing_item_description
    return I18n.t("cultivation_events.found_equipment_item.description_without_item") if event_key == "found_equipment_item"

    description
  end
end
