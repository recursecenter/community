require 'set'

class BroadcastNotifier < Notifier
  attr_reader :post

  def initialize(post)
    @post = post
  end

  def notify(email_recipients)
    mail = NotificationMailer.broadcast_email(email_recipients, post)
    BatchMailSender.new(mail).delay.deliver
  end

  def possible_recipients
    @possible_recipients ||= GroupMembership.where(group_id: post.broadcast_groups).
      distinct_by_user_id.
      includes(:user).
      map(&:user).
      select { |u| Ability.new(u).can? :read, post }.
      to_set
  end
end
