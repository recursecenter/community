class ThreadSubscriptionNotifier < Notifier
  attr_reader :thread

  def initialize(thread)
    @thread = thread
  end

  def notify(post, email_recipients)
    mail = NotificationMailer.new_post_in_subscribed_thread_email(email_recipients, post, thread)
    BatchMailSender.new(mail).delay.deliver
  end

  def possible_recipients
    @possible_recipients ||= thread.subscribed_users.to_set
  end
end
