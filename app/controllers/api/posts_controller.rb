class Api::PostsController < Api::ApiController
  load_and_authorize_resource :post

  def create
    if @post.save!
      PubSub.publish :created, :post, @post
    end
  end

  def update
    @post.update!(update_params)
  end

private

  def create_params
    thread = DiscussionThread.find(params[:thread_id])
    params.require(:post).permit(:body).
      merge(thread: thread, author: current_user)
  end

  def update_params
    params.require(:post).permit(:body)
  end
end
