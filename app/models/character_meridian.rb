class CharacterMeridian < ApplicationRecord
  MERIDIANS = {
    "lung" => { stat: :qi_gain, bonus_per_subpoint: 1.0 },
    "large_intestine" => { stat: :wen_gain, bonus_per_subpoint: 1.5 },
    "stomach" => { stat: :health, bonus_per_subpoint: 2.0 },
    "spleen" => { stat: :expedition_reward, bonus_per_subpoint: 1.5 },
    "heart" => { stat: :breakthrough_stability, bonus_per_subpoint: 1.0 },
    "small_intestine" => { stat: :sparring_recovery, bonus_per_subpoint: 1.0 },
    "bladder" => { stat: :defense, bonus_per_subpoint: 1.5 },
    "kidney" => { stat: :power, bonus_per_subpoint: 1.0 },
    "pericardium" => { stat: :critical_rate, bonus_per_subpoint: 0.5 },
    "triple_burner" => { stat: :refinement, bonus_per_subpoint: 1.0 },
    "gallbladder" => { stat: :accuracy, bonus_per_subpoint: 1.0 },
    "liver" => { stat: :evasion, bonus_per_subpoint: 1.0 }
  }.freeze

  MAX_SUBPOINTS = 9

  belongs_to :character

  scope :active, -> { where(active: true) }

  validates :key, presence: true, inclusion: { in: MERIDIANS.keys }
  validates :opened_subpoints, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: MAX_SUBPOINTS
  }
  validate :active_meridian_limit
  validate :active_meridian_must_be_opened

  def self.ordered_keys = MERIDIANS.keys

  def localized_name
    I18n.t("meridians.names.#{key}")
  end

  def localized_bonus_name
    I18n.t("meridians.bonuses.#{stat_key}")
  end

  def stat_key
    MERIDIANS.fetch(key).fetch(:stat)
  end

  def bonus_per_subpoint
    MERIDIANS.fetch(key).fetch(:bonus_per_subpoint)
  end

  def total_bonus
    opened_subpoints * bonus_per_subpoint
  end

  def stat_bonus(stat)
    return 0 unless active?
    return 0 unless stat_key == stat.to_sym

    total_bonus
  end

  def next_subpoint
    opened_subpoints + 1
  end

  def fully_opened?
    opened_subpoints >= MAX_SUBPOINTS
  end

  def can_open_next?
    !fully_opened? && character.realm >= next_subpoint
  end

  def qi_cost
    character.meridian_qi_cost_for(next_subpoint)
  end

  def wen_cost
    character.meridian_wen_cost_for(next_subpoint)
  end

  def open_next_subpoint!
    return :complete if fully_opened?
    return :realm_locked if character.realm < next_subpoint
    return :wen_missing if character.currency < wen_cost
    return :qi_missing if character.cultivation_qi_total < qi_cost

    paid_qi = qi_cost
    paid_wen = wen_cost

    transaction do
      character.currency -= paid_wen
      character.lose_cultivation_qi!(paid_qi, save: false)
      self.opened_subpoints = next_subpoint
      self.active = true if character.character_meridians.active.count < Character::ACTIVE_MERIDIAN_LIMIT
      character.save!
      save!
      create_opening_event!(qi_cost: paid_qi, wen_cost: paid_wen)
    end

    :opened
  end

  private

  def active_meridian_limit
    return unless active?
    return unless character

    active_count = character.character_meridians.active.where.not(id:).count
    return if active_count < Character::ACTIVE_MERIDIAN_LIMIT

    errors.add(:active, :too_many)
  end

  def active_meridian_must_be_opened
    errors.add(:active, :closed) if active? && opened_subpoints.zero?
  end

  def create_opening_event!(qi_cost:, wen_cost:)
    character.game_events.create!(
      event_key: "meridian_opening",
      outcome: "positive",
      title: "meridians.events.opened.title",
      description: "meridians.events.opened.description",
      metadata: {
        "meridian_key" => key,
        "subpoint" => opened_subpoints,
        "qi_cost" => qi_cost,
        "wen_cost" => wen_cost
      },
      qi_delta: -qi_cost,
      happened_at: Time.current
    )
  end
end
