class Api::PostsController < Api::ApiController
  load_and_authorize_resource :post

  def create
    @post.save!
  end

  def update
    @post.update!(update_params)
  end

private

  def create_params
    thread = DiscussionThread.find(params[:thread_id])
    params.require(:post).permit(:body).
      merge(thread: thread)
  end

  def update_params
    params.require(:post).permit(:body)
  end
end
