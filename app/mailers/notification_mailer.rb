class NotificationMailer < ActionMailer::Base
  add_template_helper ApplicationHelper

  default from: "bot@mail.community.hackerschool.com"

  def user_mentioned_email(mention)
    @post = mention.post
    @user = mention.user
    @mentioned_by = mention.mentioned_by

    @punctuated_thread_title = @post.thread.title
    unless @punctuated_thread_title[-1].match /[.?!]/
      @punctuated_thread_title += "."
    end

    @quoted_post_body = quoted_post_body(@post)

    mail(to: @user.email,
         subject: %{#{@mentioned_by.name} mentioned you in "#{@post.thread.title}"})
  end

  def broadcast_email(users, post)
    @post = post
    @group_names = post.broadcast_groups.map(&:name)

    mail(to: users.map(&:email),
         subject: "Community broadcast: #{@post.thread.title}")
  end

  def new_post_in_subscribed_thread_email(users, post)
    @post = post

    @quoted_post_body = quoted_post_body(@post)

    mail(to: users.map(&:email),
         subject: %{New post in "#{post.thread.title}"})
  end

  def new_thread_in_subscribed_subforum_email(users, thread)
    @thread = thread

    @quoted_post_body = quoted_post_body(@thread.posts.first)

    mail(to: users.map(&:email),
         subject: %{New thread "#{thread.title}" in #{thread.subforum.name}})
  end

private
  def quoted_post_body(post)
    post.body.split("\n").map do |line|
      "> #{line}"
    end.join("\n")
  end
end
