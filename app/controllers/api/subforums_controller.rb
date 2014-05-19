class Api::SubforumsController < Api::ApiController
  def show
    @subforum = Subforum.find(params[:id])
  end
end
