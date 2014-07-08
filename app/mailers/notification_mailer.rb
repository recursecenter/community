require 'base64'
require 'json'

class NotificationMailer < ActionMailer::Base
  add_template_helper ApplicationHelper
  DEFAULT_FROM = "bot@mail.community.hackerschool.com"

  default from: DEFAULT_FROM

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

  def broadcast_email(users, post, groups)
    @post = post
    @group_names = groups.map(&:name)

    mail(to: users.map(&:email),
         subject: "Community broadcast: #{@post.thread.title}")
  end

private
  def quoted_post_body(post)
    post.body.split("\n").map do |line|
      "> #{line}"
    end.join("\n")
  end
end
