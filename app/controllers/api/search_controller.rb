class Api::SearchController < Api::ApiController
  skip_authorization_check only: [:query, :suggestions]
  def query
    @results = Post.search(params[:q])
  end

  def suggestions
    @suggestions = User.suggest(params[:q])
  end
end