class Api::ThreadsController < Api::ApiController
  def show
    @thread = DiscussionThread.find(params[:id])
  end
end
