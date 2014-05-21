class Api::PostsController < Api::ApiController
  def create
    thread = DiscussionThread.find(params[:thread_id])
    @post = current_user.posts.create(post_params.merge(thread: thread))
  end

private

  def post_params
    params.require(:post).permit(:body)
  end
end
