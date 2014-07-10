class Api::PostsController < Api::ApiController
  load_and_authorize_resource :post

  include NotifyMentionedUsers
  include NotifyBroadcastGroups

  def create
    @post.save!
    @post.thread.mark_as_visited_for(current_user)
    PubSub.publish :created, :post, @post
    notify_broadcast_groups!(@post)
    notify_newly_mentioned_users!(@post)
  end

  def update
    notify_newly_mentioned_users!(@post)
    @post.update!(update_params)
    PubSub.publish :updated, :post, @post
  end

private
  def create_params
    thread = DiscussionThread.find(params[:thread_id])
    post_params.merge(thread: thread, author: current_user)
  end

  def update_params
    post_params
  end

  def post_params
    params.require(:post).permit(:body).
      merge(broadcast_groups: Group.where(id: params.permit(broadcast_to: [])[:broadcast_to]))
  end
end
