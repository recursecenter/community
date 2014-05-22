class Api::PostsController < Api::ApiController
  def create
    thread = DiscussionThread.find(params[:thread_id])
    @post = current_user.posts.create!(post_params.merge(thread: thread))
  end

  def update
    # TODO: send back a :forbidden if we can't find the post.
    @post = current_user.posts.find(params[:id])
    @post.update!(post_params)
  end

private

  def post_params
    params.require(:post).permit(:body)
  end
end
