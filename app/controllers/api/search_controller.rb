class Api::SearchController < Api::ApiController
  skip_authorization_check only: [:query, :suggestions]
  def query
    @current_page = [params[:page].to_i - 1, 0].max
    @query = params[:q]
    @filters = params[:filters]

    response = Post.search(params[:q], params[:filters], @current_page)

    # Eager load everything related to a post that we need
    @records = response.records.includes({thread: [{subforum: :subforum_group}]}, :author)

    # Collect highlights for every record
    @highlights = Hash[response.collect {|response| [response.id, response.highlight.body]}]

    # Search metadata
    @hits = response.results.total
    @total_pages = (response.results.total / Post::RESULTS_PER_PAGE) + 1
  end

  def suggestions
    @users = User.suggest(params[:q])
    @threads = DiscussionThread.suggest(params[:q])
    @subforums = Subforum.suggest(params[:q])
  end
end