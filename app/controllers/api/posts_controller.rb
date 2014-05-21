class Api::PostsController < Api::ApiController
  def create
    @post = current_user.posts.create(post_params)
  end

private

  def post_params
    params.require(:post).permit(:body).merge(thread_id: params[:thread_id])
  end
end
