class NotificationMailer < ActionMailer::Base
  add_template_helper ApplicationHelper

  RCPT_TO = EventMachineSmtpDelivery::CUSTOM_RCPT_TO_HEADER

  include EmailFields

  def user_mentioned_email(mention)
    @post = mention.post
    @user = mention.user
    @mentioned_by = mention.mentioned_by

    reply_info = ReplyInfoVerifier.generate(@user, @post)

    headers[RCPT_TO] = @user.email

    if @post.previous_message_id
      headers["In-Reply-To"] = @post.previous_message_id
    end

    mail(message_id: @post.message_id,
         to: list_address(@post.thread.subforum),
         from: @mentioned_by.display_email,
         reply_to: reply_to_post_address(reply_info),
         subject: subforum_thread_subject(@post.thread),
         "List-Id" => list_id(@post.thread.subforum))
  end

  def broadcast_email(user, post)
    @user = user
    @post = post
    @group_names = post.broadcast_groups.map(&:name)

    if @post.previous_message_id
      headers["In-Reply-To"] = @post.previous_message_id
    end

    reply_info = ReplyInfoVerifier.generate(@user, @post)

    headers[RCPT_TO] = @user.email

    mail(message_id: @post.message_id,
         to: list_address(@post.thread.subforum),
         from: @post.author.display_email,
         subject: subforum_thread_subject(@post.thread),
         reply_to: reply_to_post_address(reply_info),
         "List-Id" => list_id(@post.thread.subforum))
  end

  def new_post_in_subscribed_thread_email(user, post)
    @user = user
    @post = post

    reply_info = ReplyInfoVerifier.generate(@user, @post)


    headers[RCPT_TO] = @user.email

    if @post.previous_message_id
      headers["In-Reply-To"] = @post.previous_message_id
    end

    mail(message_id: @post.message_id,
         to: list_address(@post.thread.subforum),
         from: @post.author.display_email,
         subject: subforum_thread_subject(@post.thread),
         reply_to: reply_to_post_address(reply_info),
         "List-Id" => list_id(@post.thread.subforum))
  end

  def new_thread_in_subscribed_subforum_email(user, thread)
    thread_subscription_email(user, thread)
  end

  def new_subscribed_thread_in_subscribed_subforum_email(user, thread)
    thread_subscription_email(user, thread)
  end

private
  def thread_subscription_email(user, thread)
    @user = user
    @thread = thread

    reply_info = ReplyInfoVerifier.generate(@user, @thread.posts.first)

    headers[RCPT_TO] = @user.email

    mail(message_id: @thread.posts.first.message_id,
         to: list_address(@thread.subforum),
         from: @thread.created_by.display_email,
         subject: subforum_thread_subject(@thread),
         reply_to: reply_to_post_address(reply_info),
         "List-Id" => list_id(@thread.subforum))
  end
end
