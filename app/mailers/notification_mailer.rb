class NotificationMailer < ActionMailer::Base
  add_template_helper ApplicationHelper

  default from: "bot@mail.community.hackerschool.com"

  def user_mentioned_email(mention)
    @post = mention.post
    @user = mention.user
    @mentioned_by = mention.mentioned_by

    mail(to: @user.email,
         from: from_field(@mentioned_by),
         subject: @post.thread.title)
  end

  def broadcast_email(users, post)
    @post = post
    @group_names = post.broadcast_groups.map(&:name)

    mail(to: users.map(&:email),
         from: from_field(@post.author),
         subject: @post.thread.title)
  end

  def new_post_in_subscribed_thread_email(users, post)
    @post = post

    mail(to: users.map(&:email),
         from: from_field(@post.author),
         subject: post.thread.title)
  end

  def new_thread_in_subscribed_subforum_email(users, thread)
    @thread = thread

    mail(to: users.map(&:email),
         from: from_field(@thread.created_by),
         subject: thread.title)
  end

private
  def from_field(user)
    "\"#{user.name} (via Community)\" <bot@mail.community.hackerschool.com>"
  end
end
