require 'set'

class SubforumSubscriptionNotifier < Notifier
  include RecipientVariables

  attr_reader :thread, :first_post

  def initialize(thread)
    @thread = thread
    @first_post = thread.posts.first
  end

  def notify(email_recipients)
    unless email_recipients.empty?
      BatchNotificationSender.delay.deliver(:new_thread_in_subscribed_subforum_email, recipient_variables(email_recipients, first_post), email_recipients.map(&:id), thread)
    end
  end

  def possible_recipients
    @possible_recipients ||= if first_post.broadcast_to_subscribers?
      thread.subforum.subscribers.
        where.not(id: thread.created_by).
        select { |u| Ability.new(u).can? :read, thread }.
        to_set
    else
      Set.new
    end
  end
end
