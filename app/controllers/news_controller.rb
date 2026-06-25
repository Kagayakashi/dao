class NewsController < ApplicationController
  before_action :load_character

  def index
    @news_posts = NewsPost.published.latest_first.includes(:rich_text_body)
  end

  def show
    @news_post = NewsPost.published.find(params[:id])
    mark_read
  end

  def read_all
    now = Time.current
    NewsPost.unread_by(@character).find_each do |news_post|
      NewsRead.create!(character: @character, news_post:, read_at: now)
    end

    redirect_to news_index_path, notice: t("news.read_all.notice"), status: :see_other
  end

  private

  def load_character
    @character = Current.user.character || Current.user.create_character!
  end

  def mark_read
    NewsRead.find_or_create_by!(character: @character, news_post: @news_post) do |read|
      read.read_at = Time.current
    end
  end
end
