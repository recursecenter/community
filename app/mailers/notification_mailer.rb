class NotificationMailer < ActionMailer::Base
  add_template_helper ApplicationHelper

  RCPT_TO = EventMachineSmtpDelivery::CUSTOM_RCPT_TO_HEADER

  def user_mentioned_email(mention)
    @user = mention.user
    @post = mention.post
    @mentioned_by = mention.mentioned_by

    make_mail(@user, @post)
  end

  def broadcast_email(user, post)
    @user = user
    @post = post
    @group_names = post.broadcast_groups.map(&:name)

    make_mail(@user, @post)
  end

  def new_post_in_subscribed_thread_email(user, post)
    @user = user
    @post = post

    make_mail(@user, @post)
  end

  def new_thread_in_subscribed_subforum_email(user, thread)
    @user = user
    @thread = thread

    make_mail(@user, @thread.posts.first)
  end

  def new_subscribed_thread_in_subscribed_subforum_email(user, thread)
    @user = user
    @thread = thread

    make_mail(@user, @thread.posts.first)
  end

private
  def make_mail(user, post)
    reply_info = ReplyInfoVerifier.generate(user, post)

    if post.previous_message_id
      headers["In-Reply-To"] = post.previous_message_id
    end

    mail(
      message_id: post.message_id,
      RCPT_TO => user.email,
      to: list_address(post.thread.subforum),
      from: post.author.display_email,
      subject: subforum_thread_subject(post.thread),
      reply_to: reply_to_post_address(reply_info),
      "List-Id" => list_id(post.thread.subforum)
    )
  end

  def reply_to_post_address(reply_info)
    "Community <reply-#{reply_info}@mail.community.hackerschool.com>"
  end

  def list_address(subforum)
    "#{subforum.name.downcase.gsub(/\s+/, '-')}@lists.community.hackerschool.com"
  end

  def subforum_thread_subject(thread)
    "[Community - #{thread.subforum.name}] #{thread.title}"
  end

  def list_id(subforum)
    "<#{subforum.name.downcase.gsub(/\s+/, '-')}.community.hackerschool.com>"
  end
end
