require 'set'

class SubforumSubscriptionNotifier < Notifier
  attr_reader :thread, :first_post

  def initialize(thread)
    @thread = thread
    @first_post = thread.posts.first
  end

  def notify(email_recipients)
    subscribed_to_thread, not_subscribed_to_thread = email_recipients.partition(&:subscribe_new_thread_in_subscribed_subforum)

    send_emails(:new_subscribed_thread_in_subscribed_subforum_email, subscribed_to_thread)
    send_emails(:new_thread_in_subscribed_subforum_email, not_subscribed_to_thread)
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

private
  def send_emails(method, recipients)
    if recipients.present?
      Delayed::Job.enqueue BatchNotificationJob.new(method, recipients, thread)
    end
  end
end
