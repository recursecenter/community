class Api::PostsController < Api::ApiController
  load_and_authorize_resource :post

  include MentionedUsers
  include PostParams

  def create
    @post.save!
    @post.mark_as_visited(current_user)
    PubSub.publish :created, :post, @post

    NotificationCoordinator.new(
      MentionNotifier.new(@post, mentioned_users),
      ThreadSubscriptionNotifier.new(@post),
      BroadcastNotifier.new(@post)
    ).notify
  end

  def update
    MentionNotifier.new(@post, mentioned_users).notify

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
end
