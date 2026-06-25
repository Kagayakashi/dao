class NewsPost < ApplicationRecord
  has_rich_text :body
  has_many :news_reads, dependent: :destroy

  validates :title, presence: true, length: { maximum: 120 }
  validates :published_at, presence: true
  validate :body_must_be_present

  scope :published, -> { where(published_at: ..Time.current) }
  scope :latest_first, -> { order(published_at: :desc, id: :desc) }
  scope :unread_by, ->(character) { published.where.not(id: NewsRead.where(character:).select(:news_post_id)) }

  private

  def body_must_be_present
    errors.add(:body, :blank) if body.blank?
  end
end
