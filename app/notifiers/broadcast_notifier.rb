require 'set'

class BroadcastNotifier < Notifier
  include RecipientVariables
  include ActionView::Helpers::TextHelper # pluralize

  attr_reader :post

  def initialize(post)
    @post = post
  end

  def notify(email_recipients)
    # Guard against accidentally broadcasting a post without broadcast groups.
    # See: https://github.com/hackerschool/community/issues/148
    if post.broadcast_groups.empty?
      Rails.logger.error("Attempted to broadcast Post(id=#{post.id}) to #{pluralize(email_recipients.size, "recipient")} (with #{pluralize(possible_recipients.size, "possible recipient")}).")
      return
    end

    unless email_recipients.empty?
      BatchNotificationSender.delay.deliver(:broadcast_email, recipient_variables(email_recipients, post.thread), email_recipients, post)
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
