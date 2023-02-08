class Api::SearchController < Api::ApiController
  skip_authorization_check only: [:search, :suggestions]

  def search
    @current_page = [params[:page].to_i, 1].max
    @query = params[:q]
    @filters = params[:filters]&.permit(:author)&.to_h

    @posts = Post.page(@current_page).per(Searchable::RESULTS_PER_PAGE)

    if @query.present?
      @posts = @posts.search(@query).with_pg_search_highlight
    else
      @posts = @posts.select("posts.*", "ts_headline(posts.body, to_tsquery('simple', '')) AS pg_search_highlight")
    end

    if @filters.present? && @filters[:author].present?
      users = User.where("users.first_name || ' ' || users.last_name = ?", @filters[:author])

      @posts = @posts.where(author_id: users)

      if @query.blank?
        @posts = @posts.order(created_at: :desc)
      end
    end

    @posts = @posts.joins(:thread).where(discussion_threads: {subforum_id: Subforum.for_user(current_user)})

    # Eager load everything related to a post that we need
    @posts = @posts.includes(:author, thread: {subforum: :subforum_group})

    # Search metadata
    @hits = @posts.total_count
    @total_pages = (@hits.to_f / Searchable::RESULTS_PER_PAGE).ceil
  end

  def suggestions
    @users = User.suggest(current_user, params[:q])
    @threads = DiscussionThread.suggest(current_user, params[:q])
    @subforums = Subforum.suggest(current_user, params[:q])
  end
end
