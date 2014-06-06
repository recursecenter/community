class Api::PostsController < Api::ApiController
  load_and_authorize_resource :post

  def create
    @post.save!
    PubSub.publish :created, :post, @post

    @post.thread.mark_as_visited_for(current_user)
  end

  def update
    @post.update!(update_params)
    PubSub.publish :updated, :post, @post
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
