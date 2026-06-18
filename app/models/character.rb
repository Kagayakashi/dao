class Character < ApplicationRecord
  INVENTORY_SLOTS = 10

  belongs_to :user
  has_many :character_achievements, dependent: :destroy
  has_many :game_events, dependent: :destroy
  has_many :character_event_cooldowns, dependent: :destroy
  has_many :inventory_items, dependent: :destroy

  alias_attribute :realm, :level
  alias_attribute :star, :sublevel
  alias_attribute :qi, :experience

  class_attribute :stars_per_realm, default: 9
  class_attribute :base_qi_required, default: 5_845
  class_attribute :realm_qi_growth, default: 30**(1.0 / 4)
  class_attribute :star_qi_growth, default: 1.12
  class_attribute :base_qi_per_second, default: 1
  class_attribute :cultivation_multiplier, default: 1.0
  class_attribute :offline_cultivation_multiplier, default: 1.0
  class_attribute :breakthrough_overflow_loss_range, default: 10..65
  class_attribute :base_power, default: 100
  class_attribute :realm_power_multiplier, default: 2.0
  class_attribute :star_power_multiplier, default: 0.12

  before_validation :set_initial_last_online, on: :create
  before_validation :set_default_name, on: :create

  validates :name, presence: true, length: { maximum: 40 }
  validates :level, :sublevel, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :experience, :total_experience, :currency, :reset,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :last_online, presence: true

  def qi_required_for_next_star
    (base_qi_required * (realm_qi_growth**(realm - 1)) * (star_qi_growth**(star - 1))).ceil
  end

  def cultivation_progress
    return 0.0 if qi_required_for_next_star <= 0

    [ qi.to_f / qi_required_for_next_star, 1.0 ].min
  end

  def realm_name
    I18n.t("characters.realms.#{realm}", default: I18n.t("characters.realms.fallback", realm:))
  end

  def qi_until_next_star
    [ qi_required_for_next_star - qi, 0 ].max
  end

  def power
    cultivation_power + equipment_power
  end

  def cultivation_power
    (base_power * (realm_power_multiplier**(realm - 1)) * (1 + ((star - 1) * star_power_multiplier))).floor
  end

  def equipment_power
    inventory_items.equipped.sum(&:inventory_power)
  end

  def recent_game_events(limit = 3)
    game_events.order(happened_at: :desc).limit(limit)
  end

  def free_inventory_slot
    used_slots = inventory_items.in_inventory.pluck(:inventory_slot)
    (1..INVENTORY_SLOTS).find { |slot| used_slots.exclude?(slot) }
  end

  def inventory_full?
    free_inventory_slot.nil?
  end

  def equip_item!(item, preferred_slot: nil)
    return false unless item.character == self && item.inventory_slot.present?

    slot = equipment_slot_for(item, preferred_slot:)
    return false unless slot

    item.update!(inventory_slot: nil, equipment_slot: slot)
  end

  def unequip_item!(item)
    return false unless item.character == self && item.equipment_slot.present?

    slot = free_inventory_slot
    return false unless slot

    item.update!(equipment_slot: nil, inventory_slot: slot)
  end

  def create_inventory_item!(name:, equipment_kind:, power_options:)
    slot = free_inventory_slot
    return false unless slot

    inventory_items.create!(name:, equipment_kind:, power_options:, inventory_slot: slot)
  end

  def gain_qi(amount, multiplier: cultivation_multiplier)
    gained_qi = (amount.to_f * multiplier).floor
    return 0 if gained_qi <= 0

    self.qi += gained_qi
    self.total_experience += gained_qi
    award_earned_achievements if persisted?
    gained_qi
  end

  def ready_for_breakthrough?
    qi >= qi_required_for_next_star
  end

  def breakthrough!(loss_percent: nil)
    return false unless ready_for_breakthrough?

    self.qi -= qi_required_for_next_star
    loss_percent ||= rand(breakthrough_overflow_loss_range)
    lost_qi = breakthrough_overflow_loss(loss_percent)
    self.qi -= lost_qi
    self.star += 1

    if star > stars_per_realm
      self.realm += 1
      self.star = 1
    end

    award_earned_achievements if persisted?
    save!
    { lost_qi:, loss_percent: }
  end

  def earned_achievement_details
    earned_keys = character_achievements.order(:earned_at).pluck(:key)
    ACHIEVEMENTS.slice(*earned_keys).map do |key, achievement|
      {
        name: I18n.t("characters.achievements.#{key}.name"),
        description: I18n.t("characters.achievements.#{key}.description"),
        predicate: achievement.fetch(:predicate)
      }
    end
  end

  def offline_qi_available(at: Time.current)
    return 0 unless last_online.present?

    elapsed_seconds = (at - last_online).floor
    return 0 if elapsed_seconds <= 0

    (elapsed_seconds * base_qi_per_second * offline_cultivation_multiplier).floor
  end

  def cultivate_offline!(at: Time.current)
    gained_qi = offline_qi_available(at:)
    gain_qi(gained_qi, multiplier: 1.0)
    self.last_online = at
    save!
    gained_qi
  end

  private

  def set_initial_last_online
    self.last_online ||= Time.current
  end

  def set_default_name
    self.name = name.presence || I18n.t("characters.default_name")
  end

  def breakthrough_overflow_loss(loss_percent)
    return 0 if qi <= 0

    (qi * loss_percent / 100.0).floor
  end

  def equipment_slot_for(item, preferred_slot: nil)
    possible_slots = item.equipment_kind == "ring" ? InventoryItem::RING_SLOTS : [ item.equipment_kind ]
    possible_slots = [ preferred_slot ] & possible_slots if preferred_slot.present?

    possible_slots.find { |slot| inventory_items.equipped.where(equipment_slot: slot).none? }
  end

  def award_earned_achievements
    ACHIEVEMENTS.each do |key, achievement|
      next unless send(achievement[:predicate])

      character_achievements.find_or_create_by!(key:) do |earned|
        earned.earned_at = Time.current
      end
    end
  end

  def first_star_breakthrough_earned?
    realm > 1 || star > 1
  end

  def first_realm_breakthrough_earned?
    realm > 1
  end

  def thousand_qi_earned?
    total_experience >= 1_000
  end

  ACHIEVEMENTS = {
    "first_star" => {
      predicate: :first_star_breakthrough_earned?
    },
    "first_realm" => {
      predicate: :first_realm_breakthrough_earned?
    },
    "thousand_qi" => {
      predicate: :thousand_qi_earned?
    }
  }.freeze
end
