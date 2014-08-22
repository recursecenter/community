class NotificationMailer < ActionMailer::Base
  add_template_helper ApplicationHelper

  include EmailFields

  def user_mentioned_email(mention)
    @post = mention.post
    @user = mention.user
    @mentioned_by = mention.mentioned_by

    reply_token = ReplyInfoVerifier.generate(@user, @post)

    headers["X-Mailgun-Variables"] = JSON.generate({reply_token: reply_token})
    headers["In-Reply-To"] = @post.previous_message_id

    mail(message_id: @post.message_id,
         to: @user.email,
         from: from_field(@mentioned_by.name),
         reply_to: reply_to_field(reply_token),
         subject: subject_field(@post.thread.title))
  end

  def broadcast_email(users, post)
    @post = post
    @group_names = post.broadcast_groups.map(&:name)

    headers["In-Reply-To"] = @post.previous_message_id

    mail(message_id: @post.message_id,
         to: users.map(&:email),
         from: from_field(@post.author.name),
         subject: subject_field(@post.thread.title))
  end

  def new_post_in_subscribed_thread_email(users, post)
    @post = post

    headers["In-Reply-To"] = @post.previous_message_id

    mail(message_id: @post.message_id,
         to: users.map(&:email),
         from: from_field(@post.author.name),
         subject: subject_field(post.thread.title))
  end

  def new_thread_in_subscribed_subforum_email(users, thread)
    @thread = thread

    mail(message_id: @thread.posts.first.message_id,
         to: users.map(&:email),
         from: from_field(@thread.created_by.name),
         subject: subject_field(thread.title))
  end

private
  def subject_field(thread_title)
    "[Community] #{thread_title}"
  end
end
