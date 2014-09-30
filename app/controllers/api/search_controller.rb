class Api::SearchController < Api::ApiController
  skip_authorization_check only: [:query, :suggestions]
  def query
    @results = Post.search(params[:q])
  end

  def suggestions
    @users = User.suggest(params[:q])
    @threads = DiscussionThread.suggest(params[:q])
    @subforums = Subforum.suggest(params[:q])
  end
end