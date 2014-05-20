class Api::SubforumsController < Api::ApiController
  def show
    @subforum = Subforum.includes(:threads).find(params[:id])
  end
end
