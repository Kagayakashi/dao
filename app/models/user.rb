class User < ApplicationRecord
  attr_accessor :character_name, :character_gender

  COMPLETION_REWARD_QI = 1_000

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :character, dependent: :destroy

  after_create :create_initial_character

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true
  validates :character_name, presence: true, if: :temporary?, on: :create
  validate :character_name_is_unique, if: -> { character_name.present? }, on: :create

  def complete_registration!(email_address:, password:, password_confirmation:)
    transaction do
      update!(
        email_address:,
        password:,
        password_confirmation:,
        temporary: false
      )
      character.gain_qi(COMPLETION_REWARD_QI)
      character.save!
    end
  end

  private

  def create_initial_character
    create_character!(name: character_name.presence, gender: character_gender.presence || :male)
  end

  def character_name_is_unique
    errors.add(:character_name, :taken) if Character.exists?(name: character_name)
  end
end
