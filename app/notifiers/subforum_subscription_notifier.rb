class SubforumSubscriptionNotifier < Notifier
  attr_reader :subforum

  def initialize(subforum)
    @subforum = subforum
  end

  def notify(thread, email_recipients)
    mail = NotificationMailer.new_thread_in_subscribed_subforum_email(email_recipients, thread, subforum)
    BatchMailSender.new(mail).delay.deliver
  end

  def possible_recipients
    @possible_recipients ||= subforum.subscribed_users.to_set
  end
end

