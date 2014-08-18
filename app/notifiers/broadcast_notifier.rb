require 'set'

class BroadcastNotifier < Notifier
  include RecipientVariables

  attr_reader :post

  def initialize(post)
    @post = post
  end

  def notify(email_recipients)
    unless email_recipients.empty?
      BatchNotificationSender.delay.deliver(:broadcast_email, recipient_variables(email_recipients, post), email_recipients, post)
    end
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
