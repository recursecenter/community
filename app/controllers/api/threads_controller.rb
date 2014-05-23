class Api::ThreadsController < Api::ApiController
  load_and_authorize_resource :thread, class: 'DiscussionThread'

  def show
  end

  def create
    if @thread.save!
      @thread.posts.create!(post_params)
    end
  end

private
  def create_params
    subforum = Subforum.find(params[:subforum_id])
    params.require(:thread).permit(:title).
      merge(created_by: current_user, subforum: subforum)
  end

  def post_params
    params.require(:post).permit(:body).merge(author: current_user)
  end
end
