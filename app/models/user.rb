class User < ApplicationRecord
  attr_accessor :character_name

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :character, dependent: :destroy

  after_create :create_initial_character

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :email_address, presence: true, uniqueness: true

  private

  def create_initial_character
    create_character!(name: character_name.presence)
  end
end
