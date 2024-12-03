require 'set'

class ThreadSubscriptionNotifier < Notifier
  attr_reader :post

  def initialize(post)
    @post = post
  end

  def notify(email_recipients=possible_recipients, exclude_emails=[])
    unless email_recipients.empty?
      Delayed::Job.enqueue BatchNotificationJob.new(:new_post_in_subscribed_thread_email, email_recipients, post)
    end
  end

  def possible_recipients
    @possible_recipients ||= if post.broadcast_to_subscribers?
      subscribers = post.thread.subscribers

      if post.created_via_email?
        excluded_users = User.where(email: exclude_emails)
        subscribers = subscribers.where.not(id: post.author_id + excluded_users.pluck(:id))
      end

      subscribers.
        select { |u| Ability.new(u).can? :read, post }.
        to_set
    else
      Set.new
    end
  end
end
