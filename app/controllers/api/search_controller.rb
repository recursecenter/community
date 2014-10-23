class Api::SearchController < Api::ApiController
  skip_authorization_check only: [:query, :suggestions]
  def query
    @page = params[:page].to_i
    @results = Post.search(params[:q], params[:filters], @page)
  end

  def suggestions
    @users = User.suggest(params[:q])
    @threads = DiscussionThread.suggest(params[:q])
    @subforums = Subforum.suggest(params[:q])
  end
end