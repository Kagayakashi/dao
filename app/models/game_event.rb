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

  def localized_qi_delta
    return if qi_delta.zero?

    qi = localized_resource_delta("qi", qi_delta)

    I18n.t("shared.qi_with_value", qi:)
  end

  private

  def localized_text(value, **options)
    return value unless value.start_with?("cultivation_events.", "sparring.", "artifact_refinements.", "spirit_expeditions.", "shops.", "meridians.", "sects.")

    I18n.t(value, **options.symbolize_keys, default: value)
  end

  def localized_metadata
    metadata.to_h
      .merge(
        "item_name" => localized_item_name,
        "name" => localized_name,
        "old_stats" => localized_stat_options(metadata["old_power_options"], fallback_power: metadata["old_power"]),
        "new_stats" => localized_stat_options(metadata["new_power_options"], fallback_power: metadata["new_power"]),
        "stats" => localized_stat_options(metadata["power_options"]),
        "meridian_name" => localized_meridian_name,
        "sect_name" => localized_sect_name,
        "rank_name" => localized_sect_rank_name,
        "qi" => localized_resource_amount("qi"),
        "wen" => localized_resource_amount("wen")
      )
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

  def localized_meridian_name
    return unless metadata["meridian_key"].present?

    I18n.t("meridians.names.#{metadata['meridian_key']}")
  end

  def localized_sect_name
    return unless metadata["sect_key"].present?

    I18n.t("sects.names.#{metadata['sect_key']}")
  end

  def localized_sect_rank_name
    return unless metadata["rank_key"].present?

    I18n.t("sects.ranks.#{metadata['rank_key']}")
  end

  def localized_stat_options(power_options, fallback_power: nil)
    options = Array(power_options).filter_map do |option|
      stat_key = option["key"]
      next if stat_key.blank?

      stat_name = I18n.t("inventory_items.power_options.#{stat_key}")
      I18n.t("inventory_items.stat_bonus", name: stat_name, value: option.fetch("value", 0))
    end

    return options.join(", ") if options.any?
    return I18n.t("inventory_items.stat_bonus", name: I18n.t("inventory_items.power_options.power"), value: fallback_power) if fallback_power.present?

    nil
  end

  def localized_resource_amount(key)
    base = metadata["base_#{key}"]
    total = metadata[key].presence || fallback_resource_amount(key)
    return ActiveSupport::NumberHelper.number_to_delimited(total) unless base.present?

    bonus = metadata["#{key}_bonus"].to_i
    value = ActiveSupport::NumberHelper.number_to_delimited(base)
    return value if bonus.zero?

    bonus_value = ActiveSupport::NumberHelper.number_to_delimited(bonus.abs)
    sign = bonus.positive? ? "+" : "-"
    "#{value} (#{sign}#{bonus_value})"
  end

  def fallback_resource_amount(key)
    return qi_delta if key == "qi" && qi_delta.present? && !qi_delta.zero?

    nil
  end

  def localized_resource_delta(key, total)
    base = metadata["base_#{key}"]
    bonus = metadata["#{key}_bonus"].to_i
    value = ActiveSupport::NumberHelper.number_to_delimited(base.presence || total)
    value = "+#{value}" if total.positive?
    return value if base.blank? || bonus.zero?

    bonus_value = ActiveSupport::NumberHelper.number_to_delimited(bonus.abs)
    sign = bonus.positive? ? "+" : "-"
    "#{value} (#{sign}#{bonus_value})"
  end

  def missing_item_description
    return I18n.t("cultivation_events.found_equipment_item.description_without_item") if event_key == "found_equipment_item"

    description
  end
end
