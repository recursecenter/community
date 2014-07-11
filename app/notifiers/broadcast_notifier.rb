class BroadcastNotifier < Notifier
  attr_reader :broadcast_groups

  def initialize(broadcast_groups)
    @broadcast_groups = broadcast_groups
  end

  def notify(post, email_recipients)
    mail = NotificationMailer.broadcast_email(email_recipients, post, broadcast_groups)
    BatchMailSender.new(mail).delay.deliver
  end

  def possible_recipients
    @possible_recipients ||= GroupMembership.where(group_id: broadcast_groups).
      distinct_by_user_id.
      includes(:user).
      map(&:user).
      to_set
  end
end
