class Api::ThreadsController < Api::ApiController
  def show
    @thread = DiscussionThread.includes(posts: [:author]).find(params[:id])
  end

  def create
    subforum = Subforum.find(params[:subforum_id])
    @thread = NewThread.create!(new_thread_params.merge(author: current_user, subforum: subforum))
  end

private
  def new_thread_params
    params.require(:thread).permit(:title, :body)
  end
end
