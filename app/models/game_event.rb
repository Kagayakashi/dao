class GameEvent < ApplicationRecord
  belongs_to :character
  belongs_to :related_character, class_name: "Character", optional: true

  validates :event_key, :outcome, :title, :description, :happened_at, presence: true
  validates :qi_delta, numericality: { only_integer: true }
end
