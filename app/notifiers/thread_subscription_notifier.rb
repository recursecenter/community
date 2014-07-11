require 'set'

class ThreadSubscriptionNotifier < Notifier
  attr_reader :post

  def initialize(post)
    @post = post
  end

  def notify(email_recipients)
    mail = NotificationMailer.new_post_in_subscribed_thread_email(email_recipients, post)
    BatchMailSender.new(mail).delay.deliver
  end

  def possible_recipients
    @possible_recipients ||= post.thread.subscribed_users.select { |u| Ability.new(u).can? :read, post }.to_set
  end
end
