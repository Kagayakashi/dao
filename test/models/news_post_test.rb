require "test_helper"

class NewsPostTest < ActiveSupport::TestCase
  test "requires title and body" do
    news_post = NewsPost.new(published_at: Time.current)

    assert_not news_post.valid?
    assert_includes news_post.errors[:title], "can't be blank"
    assert_includes news_post.errors[:body], "can't be blank"
  end

  test "finds unread published news for character" do
    character = characters(:one)
    read_post = create_news_post(title: "Read")
    unread_post = create_news_post(title: "Unread")
    NewsRead.create!(character:, news_post: read_post, read_at: Time.current)

    assert_includes NewsPost.unread_by(character), unread_post
    assert_not_includes NewsPost.unread_by(character), read_post
  end

  private

  def create_news_post(title:)
    NewsPost.create!(title:, published_at: Time.current, body: "<p>News body</p>")
  end
end
