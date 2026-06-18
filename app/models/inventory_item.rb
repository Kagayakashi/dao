class InventoryItem < ApplicationRecord
  EQUIPMENT_KINDS = %w[ weapon ring pendant ].freeze
  EQUIPMENT_SLOTS = %w[ weapon ring_one ring_two pendant ].freeze
  RING_SLOTS = %w[ ring_one ring_two ].freeze

  belongs_to :character

  serialize :power_options, coder: JSON

  before_validation :set_default_item_type

  validates :name, :item_type, :equipment_kind, presence: true
  validates :equipment_kind, inclusion: { in: EQUIPMENT_KINDS }
  validates :equipment_slot, inclusion: { in: EQUIPMENT_SLOTS }, allow_nil: true
  validates :inventory_slot, numericality: { only_integer: true }, inclusion: { in: 1..Character::INVENTORY_SLOTS }, allow_nil: true
  validate :stored_in_one_place
  validate :equipment_slot_matches_kind

  scope :in_inventory, -> { where.not(inventory_slot: nil).order(:inventory_slot) }
  scope :equipped, -> { where.not(equipment_slot: nil) }

  def equipped?
    equipment_slot.present?
  end

  def inventory_power
    power_options.sum { |option| option.fetch("value", 0).to_i }
  end

  private

  def set_default_item_type
    self.item_type = item_type.presence || "equipment"
  end

  def stored_in_one_place
    return if inventory_slot.present? ^ equipment_slot.present?

    errors.add(:base, :stored_in_one_place)
  end

  def equipment_slot_matches_kind
    return if equipment_slot.blank?
    return if equipment_kind == "ring" && RING_SLOTS.include?(equipment_slot)
    return if equipment_kind == equipment_slot

    errors.add(:equipment_slot, :equipment_slot_mismatch)
  end
end
