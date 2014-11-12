class Api::SearchController < Api::ApiController
  skip_authorization_check only: [:search, :suggestions]

  def search
    @current_page = [params[:page].to_i, 1].max
    @query = params[:q]
    @filters = params[:filters]

    # TODO: This might have to change when we are able to compose queries/filters.
    if @filters.present? && @filters[:author].present? && @query.blank?
      response = Post.search(current_user, @query, @filters, @current_page, sort: {created_at: :desc})
    else
      response = Post.search(current_user, @query, @filters, @current_page)
    end

    # Eager load everything related to a post that we need
    @posts = response.records.includes({thread: [{subforum: :subforum_group}]}, :author)

    # Collect highlights for every record
    @highlights = response.map { |result| [result.id, result.highlight.body] }.to_h

    # Search metadata
    @hits = response.results.total
    @total_pages = (response.results.total.to_f / Searchable::RESULTS_PER_PAGE).ceil
  end

  def suggestions
    @users = User.suggest(current_user, params[:q])
    @threads = DiscussionThread.suggest(current_user, params[:q])
    @subforums = Subforum.suggest(current_user, params[:q])
  end
end
