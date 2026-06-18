class CharacterAchievement < ApplicationRecord
  belongs_to :character

  validates :key, presence: true, uniqueness: { scope: :character_id }
  validates :earned_at, presence: true
end
