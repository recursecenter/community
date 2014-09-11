class Api::SearchController < Api::ApiController
  skip_authorization_check only: :query
  def query
    @results = Post.search(params[:q])
  end
end