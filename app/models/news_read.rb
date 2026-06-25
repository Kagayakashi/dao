class NewsRead < ApplicationRecord
  belongs_to :character
  belongs_to :news_post

  validates :read_at, presence: true
  validates :news_post_id, uniqueness: { scope: :character_id }
end
