class NotificationMailer < ActionMailer::Base
  add_template_helper ApplicationHelper

  include EmailFields

  def user_mentioned_email(mention)
    @post = mention.post
    @user = mention.user
    @mentioned_by = mention.mentioned_by

    reply_info = ReplyInfoVerifier.generate(@user, @post)

    headers["X-Mailgun-Variables"] = JSON.generate({reply_info: reply_info})

    if @post.previous_message_id
      headers["In-Reply-To"] = @post.previous_message_id
    end

    mail(message_id: @post.message_id,
         to: @user.email,
         from: from_field(@mentioned_by),
         reply_to: reply_to_field(reply_info),
         subject: subject_field(@post.thread))
  end

  def broadcast_email(user_ids, post)
    users = User.where(id: user_ids)
    @post = post
    @group_names = post.broadcast_groups.map(&:name)

    if @post.previous_message_id
      headers["In-Reply-To"] = @post.previous_message_id
    end

    mail(message_id: @post.message_id,
         to: users.map(&:email),
         from: from_field(@post.author),
         subject: subject_field(@post.thread))
  end

  def new_post_in_subscribed_thread_email(user_ids, post)
    users = User.where(id: user_ids)
    @post = post

    if @post.previous_message_id
      headers["In-Reply-To"] = @post.previous_message_id
    end

    mail(message_id: @post.message_id,
         to: users.map(&:email),
         from: from_field(@post.author),
         subject: subject_field(@post.thread))
  end

  def new_thread_in_subscribed_subforum_email(user_ids, thread)
    users = User.where(id: user_ids)
    @thread = thread

    mail(message_id: @thread.posts.first.message_id,
         to: users.map(&:email),
         from: from_field(@thread.created_by),
         subject: subject_field(@thread))
  end
end
