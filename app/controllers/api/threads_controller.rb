class Api::ThreadsController < Api::ApiController
  def show
    @thread = DiscussionThread.includes(posts: [:author]).find(params[:id])
  end
end
