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
    @reply_info = ReplyInfoVerifier.generate(user, post)

    if post.previous_message_id
      headers["References"] = headers["In-Reply-To"] = post.previous_message_id
    end

    mail(
      RCPT_TO => user.email,
      message_id: post.message_id,
      to: list_address(post.thread.subforum),
      from: post.author.display_email,
      subject: subforum_thread_subject(post.thread),
      reply_to: reply_to(@reply_info),

      "Precedence" => "list",
      "List-Id" => list_id(post.thread.subforum),
      "List-Archive" => list_archive(post.thread),
      "List-Post" => list_post(@reply_info),
      "List-Unsubscribe" => list_unsubscribe(@reply_info),

      # Mailgun sends these back to us when users reply to a sent email
      "X-Mailgun-Variables" => {reply_info: @reply_info}.to_json
    )
  end

private
  def subforum_thread_subject(thread)
    "[Community - #{thread.subforum.name}] #{thread.title}"
  end

  def reply_to(reply_info)
    "Community <#{reply_to_post_address(reply_info)}>"
  end

  def reply_to_post_address(reply_info)
    "reply-#{reply_info}@mail.community.hackerschool.com"
  end

  def list_address(subforum)
    "#{subforum.name.downcase.gsub(/\s+/, '-')}@lists.community.hackerschool.com"
  end

  def list_id(subforum)
    "<#{subforum.name.downcase.gsub(/\s+/, '-')}.community.hackerschool.com>"
  end

  def list_archive(thread)
    thread_url(id: thread.id, slug: thread.slug)
  end

  def list_post(reply_info)
    "<mailto:#{reply_to_post_address(reply_info)}>"
  end

  def list_unsubscribe(reply_info)
    "<#{unsubscribe_thread_url(reply_info)}>"
  end
end
