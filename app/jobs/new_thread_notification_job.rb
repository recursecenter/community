class NewThreadNotificationJob
  def initialize(post, mentioned_user_ids)
    @post = post
    @mentioned_user_ids = mentioned_user_ids
  end

  def perform
    NotificationCoordinator.new(
      MentionNotifier.new(@post, mentioned_users),
      SubforumSubscriptionNotifier.new(@post.thread),
      BroadcastNotifier.new(@post)
    ).notify
  end

  def mentioned_users
    User.where(id: @mentioned_user_ids)
  end
end
