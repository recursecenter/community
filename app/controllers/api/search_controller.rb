class Api::SearchController < Api::ApiController
  skip_authorization_check only: [:query, :suggestions]
  def query
    @current_page = [params[:page].to_i, 1].max
    @query = params[:q]
    @filters = params[:filters]

    response = Post.search(current_user, @query, @filters, @current_page)

    # Eager load everything related to a post that we need
    @posts = response.records.includes({thread: [{subforum: :subforum_group}]}, :author)

    # Collect highlights for every record
    @highlights = response.map { |result| [result.id, result.highlight.body] }.to_h

    # Search metadata
    @hits = response.results.total
    @total_pages = (response.results.total / Searchable::RESULTS_PER_PAGE) + 1
  end

  def suggestions
    @users = User.suggest(current_user, params[:q])
    @threads = DiscussionThread.suggest(current_user, params[:q])
    @subforums = Subforum.suggest(current_user, params[:q])
  end
end
