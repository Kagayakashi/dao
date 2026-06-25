module Admin
  class NewsPostsController < BaseController
    before_action :set_news_post, only: %i[ edit update destroy ]

    def index
      @news_posts = NewsPost.latest_first.includes(:rich_text_body)
    end

    def new
      @news_post = NewsPost.new(published_at: Time.current)
    end

    def create
      @news_post = NewsPost.new(news_post_params)

      if @news_post.save
        redirect_to admin_news_posts_path, notice: t("admin.news_posts.create.notice")
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @news_post.update(news_post_params)
        redirect_to admin_news_posts_path, notice: t("admin.news_posts.update.notice")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @news_post.destroy!
      redirect_to admin_news_posts_path, notice: t("admin.news_posts.destroy.notice"), status: :see_other
    end

    private

    def set_news_post
      @news_post = NewsPost.find(params[:id])
    end

    def news_post_params
      params.require(:news_post).permit(:title, :published_at, :body)
    end
  end
end
