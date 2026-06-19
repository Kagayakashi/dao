class BackfillFoundEquipmentEventItemKeys < ActiveRecord::Migration[8.1]
  def up
    game_event.where(event_key: "found_equipment_item", outcome: "positive").find_each do |event|
      metadata = JSON.parse(event.metadata.presence || "{}")
      next if metadata["inventory_item_name_key"].present?

      item = matching_inventory_item(event)
      next unless item

      metadata["inventory_item_name_key"] = item.name
      event.update_columns(metadata: JSON.generate(metadata))
    end
  end

  def down
    # No-op. Keeping recovered item keys is safer than deleting useful neutral metadata.
  end

  private

  def matching_inventory_item(event)
    inventory_item
      .where(character_id: event.character_id)
      .where(created_at: (event.happened_at - 10.seconds)..(event.happened_at + 10.seconds))
      .order(Arel.sql("ABS(strftime('%s', created_at) - strftime('%s', #{connection.quote(event.happened_at)}))"))
      .first
  end

  def game_event
    Class.new(ActiveRecord::Base) do
      self.table_name = "game_events"
    end
  end

  def inventory_item
    Class.new(ActiveRecord::Base) do
      self.table_name = "inventory_items"
    end
  end
end
