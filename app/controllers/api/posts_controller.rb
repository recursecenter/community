class Api::PostsController < Api::ApiController
  load_and_authorize_resource :post

  def create
    @post.save!
    @post.thread.mark_as_visited_for(current_user)
    PubSub.publish :created, :post, @post

    NotificationCoordinator.new(
      MentionNotifier.new(@post, mentioned_users),
      BroadcastNotifier.new(@post)
    ).notify
  end

  def update
    MentionNotifier.new(@post, mentioned_users).notify(mentioned_users)

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

  def mentioned_users
    if mention_params[:mentions].present?
      User.where(id: mention_params[:mentions])
    else
      []
    end
  end

  def mention_params
    params.permit(mentions: [])
  end
end
