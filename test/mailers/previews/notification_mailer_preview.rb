# Preview all emails at http://localhost:3000/rails/mailers/notification_mailer
class NotificationMailerPreview < ActionMailer::Preview
  def user_mentioned_email
    NotificationMailer.user_mentioned_email(Notifications::Mention.first)
  end

  def broadcast_email
    NotificationMailer.broadcast_email([User.first.id], Post.first)
  end

  def new_post_in_subscribed_thread_email
    NotificationMailer.new_post_in_subscribed_thread_email([User.first.id], Post.first)
  end

  def new_thread_in_subscribed_subforum_email
    NotificationMailer.new_thread_in_subscribed_subforum_email([User.first.id], DiscussionThread.first)
  end
end
