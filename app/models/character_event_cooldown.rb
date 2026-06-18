class CharacterEventCooldown < ApplicationRecord
  belongs_to :character

  validates :event_key, presence: true, uniqueness: { scope: :character_id }
  validates :next_event_at, presence: true
end
