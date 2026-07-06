class Character < ApplicationRecord
  INVENTORY_SLOTS = 10
  ACTIVE_MERIDIAN_LIMIT = 3
  SECTS = {
    "azure_cloud" => { stat: :qi_gain, bonus: 3.0 },
    "iron_mountain" => { stat: :health, bonus: 5.0 },
    "scarlet_flame" => { stat: :power, bonus: 3.0 },
    "jade_river" => { stat: :wen_gain, bonus: 5.0 },
    "silent_moon" => { stat: :evasion, bonus: 3.0, secondary_stat: :accuracy, secondary_bonus: 3.0 },
    "wandering_dao" => { stat: :expedition_reward, bonus: 5.0 }
  }.freeze
  SECT_RANKS = [
    { key: "outer_disciple", multiplier: 1.0, promotion_cost: 0 },
    { key: "inner_disciple", multiplier: 1.5, promotion_cost: 500 },
    { key: "core_disciple", multiplier: 2.0, promotion_cost: 2_000 },
    { key: "elder", multiplier: 3.0, promotion_cost: 7_500 },
    { key: "peak_lord", multiplier: 4.0, promotion_cost: 20_000 }
  ].freeze
  SECT_DAILY_TASK_COOLDOWN = 1.day
  SECT_DAILY_TASK_CONTRIBUTION = 100
  SECT_DAILY_TASK_QI_HOURS = 2
  SECT_DAILY_TASK_WEN = 100
  SECT_DONATION_WEN_COST = 1_000
  SECT_DONATION_CONTRIBUTION = 50

  belongs_to :user
  has_many :character_achievements, dependent: :destroy
  has_many :game_events, dependent: :destroy
  has_many :character_event_cooldowns, dependent: :destroy
  has_many :inventory_items, dependent: :destroy
  has_many :news_reads, dependent: :destroy
  has_many :character_meridians, dependent: :destroy

  alias_attribute :realm, :level
  alias_attribute :star, :sublevel
  alias_attribute :qi, :experience

  enum :gender, { male: "male", female: "female" }, default: :male, validate: true

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
  class_attribute :combat_stat_config, default: CombatStats::CharacterStats::DEFAULT_CONFIG
  class_attribute :health_recovery_interval, default: 10.minutes
  class_attribute :health_recovery_percent, default: 5
  class_attribute :max_sparring_points, default: 3
  class_attribute :sparring_recovery_duration, default: 10.minutes
  class_attribute :daily_reward_base_qi, default: 1_000
  class_attribute :daily_reward_realm_bonus_qi, default: 250
  class_attribute :daily_reward_star_bonus_qi, default: 50
  class_attribute :daily_reward_cooldown, default: 1.day
  class_attribute :spirit_expedition_durations, default: [ 1, 4, 12, 24 ]
  class_attribute :spirit_expedition_extended_reward_multiplier, default: 0.75
  class_attribute :spirit_expedition_wen_reward_range, default: 50..100
  class_attribute :spirit_expedition_donation_currency_chance, default: 0.05
  class_attribute :spirit_expedition_instant_completion_cost, default: 1
  class_attribute :meridian_qi_cost_multiplier, default: 4
  class_attribute :meridian_wen_base_cost, default: 5_000
  class_attribute :meridian_wen_cost_growth, default: 1_500

  before_validation :set_initial_last_online, on: :create
  before_validation :set_default_name, on: :create
  before_validation :set_initial_sparring_recovered_at, on: :create
  before_validation :set_initial_health_recovered_at

  validates :name, presence: true, length: { maximum: 40 }, uniqueness: true
  validates :level, :sublevel, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :experience, :total_experience, :currency, :donation_currency, :reset,
    numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :current_health, numericality: { only_integer: true, greater_than_or_equal_to: 1 }, allow_nil: true
  validates :sparring_points, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: ->(character) { character.max_sparring_points } }
  validates :spirit_expedition_duration_hours, inclusion: { in: ->(character) { character.spirit_expedition_durations } }, allow_nil: true
  validates :sect_key, inclusion: { in: SECTS.keys }, allow_nil: true
  validates :sect_rank, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: SECT_RANKS.length }
  validates :sect_contribution, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :last_online, presence: true
  validates :sparring_recovered_at, presence: true
  validates :health_recovered_at, presence: true



  def qi_required_for_next_star
    (base_qi_required * (realm_qi_growth**(realm - 1)) * (star_qi_growth**(star - 1))).ceil
  end

  def cultivation_qi_total
    previous_realms_qi = (1...realm).sum do |realm_number|
      (1..stars_per_realm).sum { |star_number| qi_required_for(realm_number, star_number) }
    end
    previous_stars_qi = (1...star).sum { |star_number| qi_required_for(realm, star_number) }

    previous_realms_qi + previous_stars_qi + qi
  end

  def cultivation_progress
    return 0.0 if qi_required_for_next_star <= 0

    [ qi.to_f / qi_required_for_next_star, 1.0 ].min
  end

  def realm_name
    I18n.t("characters.realms.#{realm}", default: I18n.t("characters.realms.fallback", realm:))
  end

  def gender_name
    I18n.t("characters.genders.#{gender}")
  end

  def profile_image_name
    "#{gender}_profile.png"
  end

  def qi_until_next_star
    [ qi_required_for_next_star - qi, 0 ].max
  end

  def power
    cultivation_power + equipment_power
  end

  def cultivation_power
    (base_cultivation_power * active_meridian_multiplier(:power)).floor
  end

  def base_cultivation_power
    (base_power * (realm_power_multiplier**(realm - 1)) * (1 + ((star - 1) * star_power_multiplier))).floor
  end

  def equipment_power
    inventory_items.equipped.sum(&:inventory_power)
  end

  def equipment_stat_bonus(stat_key)
    inventory_items.equipped.sum { |item| item.stat_value(stat_key) }
  end

  def meridian_stat_bonus(stat_key)
    active_character_meridians.sum { |meridian| meridian.stat_bonus(stat_key) }
  end

  def active_meridian_multiplier(stat_key)
    1.0 + (passive_stat_bonus(stat_key) / 100.0)
  end

  def passive_stat_bonus(stat_key)
    meridian_stat_bonus(stat_key) + sect_stat_bonus(stat_key)
  end

  def sect_stat_bonus(stat_key)
    return 0 unless sect_joined?

    stat_key = stat_key.to_sym
    bonus = 0
    bonus += sect_definition.fetch(:bonus) if sect_definition.fetch(:stat) == stat_key
    bonus += sect_definition.fetch(:secondary_bonus, 0) if sect_definition[:secondary_stat] == stat_key
    bonus * sect_rank_multiplier
  end

  def gear_score
    inventory_items.equipped.sum(&:gear_score)
  end

  def damage
    combat_stat_profile.damage
  end

  def health
    combat_stat_profile.health
  end

  def defense
    combat_stat_profile.defense
  end

  def evasion
    combat_stat_profile.evasion
  end

  def accuracy
    combat_stat_profile.accuracy
  end

  def critical_rate
    combat_stat_profile.critical_rate
  end

  def current_health_points
    [ current_health.presence || health, health ].min
  end

  def recover_health!(at: Time.current)
    self.health_recovered_at ||= at
    return if current_health_points >= health

    elapsed_recoveries = ((at - health_recovered_at) / health_recovery_interval.to_i).floor
    return if elapsed_recoveries <= 0

    recovered_health = (health * (health_recovery_percent / 100.0) * elapsed_recoveries).floor
    self.current_health = [ current_health_points + recovered_health, health ].min
    self.health_recovered_at = current_health >= health ? at : health_recovered_at + (elapsed_recoveries * health_recovery_interval)
    save! if changed?
  end

  def take_damage!(amount)
    self.current_health = [ current_health_points - amount.to_i, 1 ].max
    save!
  end

  def clamp_current_health!
    clamped = [ current_health_points, health ].min
    return if current_health == clamped

    update!(current_health: clamped)
  end

  def combat_stats
    combat_stat_profile.to_h
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
    clamp_current_health!
    true
  end

  def unequip_item!(item)
    return false unless item.character == self && item.equipment_slot.present?

    slot = free_inventory_slot
    return false unless slot

    item.update!(equipment_slot: nil, inventory_slot: slot)
    clamp_current_health!
    true
  end

  def create_inventory_item!(name:, equipment_kind:, power_options:, metadata: {})
    slot = free_inventory_slot
    return false unless slot

    inventory_items.create!(name:, equipment_kind:, power_options:, metadata:, inventory_slot: slot)
  end

  def gain_qi(amount, multiplier: nil)
    multiplier ||= effective_cultivation_multiplier
    gained_qi = (amount.to_f * multiplier).floor
    return 0 if gained_qi <= 0

    self.qi += gained_qi
    self.total_experience += gained_qi
    award_earned_achievements if persisted?
    gained_qi
  end

  def apply_qi_delta!(qi_delta)
    if qi_delta.positive?
      gain_qi(qi_delta, multiplier: 1.0)
    elsif qi_delta.negative?
      lose_cultivation_qi!(-qi_delta, save: false)
    end

    save! if changed?
  end

  def lose_cultivation_qi!(amount, save: true)
    amount = amount.to_i
    return 0 if amount <= 0

    lost_qi = [ amount, cultivation_qi_total ].min
    subtract_cultivation_qi(lost_qi)
    self.total_experience = [ total_experience - lost_qi, 0 ].max
    clamp_current_health!
    save! if save && changed?
    lost_qi
  end

  def recalculate_cultivation_from_total_qi!
    assign_cultivation_from_cumulative_qi(total_experience)
    clamp_current_health!
    save! if changed?
  end

  def meridian_qi_cost_for(subpoint)
    qi_required_for(subpoint, subpoint) * meridian_qi_cost_multiplier
  end

  def meridian_wen_cost_for(subpoint)
    meridian_wen_base_cost + ((subpoint - 1) * meridian_wen_cost_growth)
  end

  def sect_joined?
    sect_key.present?
  end

  def sect_definition
    SECTS.fetch(sect_key)
  end

  def sect_name
    I18n.t("sects.names.#{sect_key}") if sect_joined?
  end

  def sect_rank_definition
    SECT_RANKS.fetch(sect_rank)
  end

  def sect_rank_key
    sect_rank_definition.fetch(:key)
  end

  def sect_rank_name
    I18n.t("sects.ranks.#{sect_rank_key}")
  end

  def sect_rank_multiplier
    sect_rank_definition.fetch(:multiplier)
  end

  def sect_bonus_name
    I18n.t("sects.bonuses.#{sect_definition.fetch(:stat)}") if sect_joined?
  end

  def sect_bonus_value
    return 0 unless sect_joined?

    sect_definition.fetch(:bonus) * sect_rank_multiplier
  end

  def sect_daily_task_ready?(at: Time.current)
    sect_joined? && sect_daily_task_available_at(at:) <= at
  end

  def sect_daily_task_available_at(at: Time.current)
    return at unless sect_task_completed_at

    sect_task_completed_at + SECT_DAILY_TASK_COOLDOWN
  end

  def join_sect!(key)
    key = key.to_s
    return :already_joined if sect_joined?
    return :unknown_sect unless SECTS.key?(key)

    update!(sect_key: key, sect_rank: 0, sect_contribution: 0, sect_task_completed_at: nil)
    create_sect_event!("joined", metadata: { "sect_key" => key, "rank_key" => sect_rank_key })
    :joined
  end

  def perform_sect_daily_task!(at: Time.current)
    return false unless sect_daily_task_ready?(at:)

    gained_qi = (base_qi_per_second * SECT_DAILY_TASK_QI_HOURS.hours.to_i).floor
    gained_wen = (SECT_DAILY_TASK_WEN * active_meridian_multiplier(:wen_gain)).floor

    transaction do
      gain_qi(gained_qi, multiplier: 1.0)
      self.currency += gained_wen
      self.sect_contribution += SECT_DAILY_TASK_CONTRIBUTION
      self.sect_task_completed_at = at
      save!
      create_sect_event!("daily_task", metadata: { "sect_key" => sect_key, "contribution" => SECT_DAILY_TASK_CONTRIBUTION, "qi" => gained_qi, "wen" => gained_wen }, qi_delta: gained_qi)
    end

    { qi: gained_qi, wen: gained_wen, contribution: SECT_DAILY_TASK_CONTRIBUTION }
  end

  def donate_to_sect!(amount: 1)
    amount = amount.to_i
    return :no_sect unless sect_joined?
    return :invalid_amount if amount < 1

    wen_cost = SECT_DONATION_WEN_COST * amount
    contribution = SECT_DONATION_CONTRIBUTION * amount
    return :wen_missing if currency < wen_cost

    transaction do
      self.currency -= wen_cost
      self.sect_contribution += contribution
      save!
      create_sect_event!("donation", metadata: { "sect_key" => sect_key, "contribution" => contribution, "wen" => wen_cost })
    end

    { status: :donated, contribution: }
  end

  def promote_sect_rank!
    return :no_sect unless sect_joined?
    return :max_rank if sect_rank >= SECT_RANKS.length - 1

    cost = SECT_RANKS.fetch(sect_rank + 1).fetch(:promotion_cost)
    return :contribution_missing if sect_contribution < cost

    transaction do
      self.sect_contribution -= cost
      self.sect_rank += 1
      save!
      create_sect_event!("promotion", metadata: { "sect_key" => sect_key, "rank_key" => sect_rank_key, "contribution" => cost })
    end

    :promoted
  end

  def ready_for_breakthrough?
    qi >= qi_required_for_next_star
  end

  def breakthrough!(loss_percent: nil)
    return false unless ready_for_breakthrough?

    self.qi -= qi_required_for_next_star
    loss_percent ||= rand(breakthrough_overflow_loss_range)
    loss_percent = [ loss_percent - meridian_stat_bonus(:breakthrough_stability), 0 ].max
    lost_qi = breakthrough_overflow_loss(loss_percent)
    self.qi -= lost_qi
    self.total_experience = [ total_experience - lost_qi, 0 ].max
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
    return 0 if spirit_expedition_active?(at:)

    gained_qi = offline_qi_available(at:)
    gain_qi(gained_qi, multiplier: 1.0)
    self.last_online = at
    save!
    gained_qi
  end

  def spirit_expedition_active?(at: Time.current)
    spirit_expedition_ends_at.present? && spirit_expedition_ends_at > at
  end

  def spirit_expedition_reward_multiplier
    duration_multiplier = spirit_expedition_duration_hours.to_i <= 1 ? 1.0 : spirit_expedition_extended_reward_multiplier

    duration_multiplier * active_meridian_multiplier(:expedition_reward)
  end

  def spirit_expedition_estimated_qi_reward(hours)
    multiplier = hours.to_i <= 1 ? 1.0 : spirit_expedition_extended_reward_multiplier

    (base_qi_per_second * hours.to_i.hours.to_i * multiplier * active_meridian_multiplier(:expedition_reward)).floor
  end

  def start_spirit_expedition!(hours:, at: Time.current)
    hours = hours.to_i
    return false unless spirit_expedition_durations.include?(hours)
    return false if spirit_expedition_active?(at:)

    cultivate_offline!(at:)
    update!(
      spirit_expedition_started_at: at,
      spirit_expedition_ends_at: at + hours.hours,
      spirit_expedition_duration_hours: hours,
      last_online: at
    )
  end

  def complete_spirit_expedition!(at: Time.current, wen_per_hour: nil, donation_currency_roll: nil)
    return false unless spirit_expedition_ends_at.present?
    return false if spirit_expedition_active?(at:)

    hours = spirit_expedition_duration_hours
    multiplier = spirit_expedition_reward_multiplier
    gained_qi = spirit_expedition_estimated_qi_reward(hours)
    gained_wen = ((wen_per_hour || rand(spirit_expedition_wen_reward_range)) * hours * multiplier * active_meridian_multiplier(:wen_gain)).floor
    donation_currency_roll ||= rand
    gained_donation_currency = hours.to_i == 1 && donation_currency_roll < spirit_expedition_donation_currency_chance ? 1 : 0

    gain_qi(gained_qi, multiplier: 1.0)
    self.currency += gained_wen
    self.donation_currency += gained_donation_currency
    self.last_online = spirit_expedition_ends_at
    self.spirit_expedition_started_at = nil
    self.spirit_expedition_ends_at = nil
    self.spirit_expedition_duration_hours = nil

    transaction do
      save!
      create_spirit_expedition_event!(hours:, wen: gained_wen)
    end

    { qi: gained_qi, wen: gained_wen, donation_currency: gained_donation_currency }
  end

  def complete_spirit_expedition_now!(at: Time.current)
    return false unless spirit_expedition_active?(at:)
    return false if donation_currency < spirit_expedition_instant_completion_cost

    self.donation_currency -= spirit_expedition_instant_completion_cost
    self.spirit_expedition_ends_at = at
    complete_spirit_expedition!(at:)
  end

  def create_spirit_expedition_event!(hours:, wen:)
    game_events.create!(
      event_key: "spirit_expedition",
      outcome: "positive",
      title: "spirit_expeditions.events.title",
      description: "spirit_expeditions.events.description",
      metadata: { "hours" => hours, "wen" => wen },
      qi_delta: 0,
      happened_at: Time.current
    )
  end

  def create_sect_event!(action, metadata:, qi_delta: 0)
    game_events.create!(
      event_key: "sect_#{action}",
      outcome: "positive",
      title: "sects.events.#{action}.title",
      description: "sects.events.#{action}.description",
      metadata:,
      qi_delta:,
      happened_at: Time.current
    )
  end

  def recover_sparring_points!(at: Time.current)
    recover_sparring_points(at:)
    save! if changed?
    sparring_points
  end

  def spend_sparring_point!(at: Time.current)
    recover_sparring_points(at:)
    return false if sparring_points.zero?

    self.sparring_recovered_at = at if sparring_points == max_sparring_points
    self.sparring_points -= 1
    save!
  end

  def sparring_recovery_due_at(at: Time.current)
    recover_sparring_points(at:)
    return if sparring_points >= max_sparring_points

    sparring_recovered_at + effective_sparring_recovery_duration
  end

  def effective_sparring_recovery_duration
    seconds = sparring_recovery_duration.to_i * (1 - (meridian_stat_bonus(:sparring_recovery) / 100.0))

    seconds.clamp(60, sparring_recovery_duration.to_i).seconds
  end

  def artifact_refinement_wen_cost
    discount = meridian_stat_bonus(:refinement) / 100.0

    (ArtifactRefinements::Reroll::WEN_COST * (1 - discount)).floor.clamp(1, ArtifactRefinements::Reroll::WEN_COST)
  end

  def available_for_sparring?
    current_health_points * 100 > health * 25
  end

  def daily_reward_ready?(at: Time.current)
    daily_reward_available_at(at:) <= at
  end

  def daily_reward_qi
    daily_reward_base_qi + ((realm - 1) * daily_reward_realm_bonus_qi) + ((star - 1) * daily_reward_star_bonus_qi)
  end

  def daily_reward_available_at(at: Time.current)
    return at unless daily_reward_claimed_at

    daily_reward_claimed_at + daily_reward_cooldown
  end

  def claim_daily_reward!(at: Time.current)
    return false unless daily_reward_ready?(at:)

    gained_qi = gain_qi(daily_reward_qi, multiplier: 1.0)
    self.daily_reward_claimed_at = at
    save!
    gained_qi
  end

  def admin_adjust_qi!(amount)
    target_qi = [ total_experience + amount.to_i, 0 ].max

    assign_cultivation_from_cumulative_qi(target_qi)
    self.total_experience = target_qi
    award_earned_achievements if persisted?
    save!
  end

  private

  def combat_stat_profile
    CombatStats::CharacterStats.new(self)
  end

  def cumulative_cultivation_qi = cultivation_qi_total

  def assign_cultivation_from_cumulative_qi(target_qi)
    self.realm = 1
    self.star = 1

    loop do
      required_qi = qi_required_for(realm, star)
      break if target_qi < required_qi

      target_qi -= required_qi
      self.star += 1

      if star > stars_per_realm
        self.realm += 1
        self.star = 1
      end
    end

    self.qi = target_qi
  end

  def subtract_cultivation_qi(amount)
    remaining_loss = amount

    while remaining_loss.positive?
      if qi >= remaining_loss
        self.qi -= remaining_loss
        break
      end

      remaining_loss -= qi

      if realm == 1 && star == 1
        self.qi = 0
        break
      end

      step_back_cultivation!
      self.qi = qi_required_for_next_star
    end
  end

  def step_back_cultivation!
    self.star -= 1

    return if star >= 1

    self.realm -= 1
    self.star = stars_per_realm
  end

  def qi_required_for(realm_number, star_number)
    (base_qi_required * (realm_qi_growth**(realm_number - 1)) * (star_qi_growth**(star_number - 1))).ceil
  end

  def effective_cultivation_multiplier
    cultivation_multiplier * active_meridian_multiplier(:qi_gain)
  end

  def active_character_meridians
    character_meridians.select(&:active?)
  end

  def set_initial_last_online
    self.last_online ||= Time.current
  end

  def set_initial_sparring_recovered_at
    self.sparring_recovered_at ||= Time.current
  end

  def set_initial_health_recovered_at
    self.health_recovered_at ||= Time.current
  end

  def recover_sparring_points(at: Time.current)
    self.sparring_recovered_at ||= at
    return if sparring_points >= max_sparring_points

    recovery_duration = effective_sparring_recovery_duration
    elapsed_recoveries = ((at - sparring_recovered_at) / recovery_duration.to_i).floor
    return if elapsed_recoveries <= 0

    recovered_points = [ elapsed_recoveries, max_sparring_points - sparring_points ].min
    self.sparring_points += recovered_points
    self.sparring_recovered_at = sparring_points >= max_sparring_points ? at : sparring_recovered_at + (recovered_points * recovery_duration)
  end

  def set_default_name
    return if name.present?

    default_name = I18n.t("characters.default_name")
    self.name = if self.class.exists?(name: default_name)
      loop do
        generated_name = "#{default_name} #{SecureRandom.alphanumeric(6)}"
        break generated_name unless self.class.exists?(name: generated_name)
      end
    else
      default_name
    end
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
