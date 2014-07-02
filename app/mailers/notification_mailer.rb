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

    @quoted_post_body = @post.body.split("\n").map do |line|
      "> #{line}"
    end.join("\n")

    mail(to: @user.email,
         subject: %{#{@mentioned_by.name} mentioned you in "#{@post.thread.title}"})
  end
end
