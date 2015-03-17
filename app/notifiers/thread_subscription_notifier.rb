require 'set'

class ThreadSubscriptionNotifier < Notifier
  attr_reader :post

  def initialize(post)
    @post = post
  end

  def notify(email_recipients=possible_recipients)
    unless email_recipients.empty?
      Delayed::Job.enqueue BatchNotificationJob.new(:new_post_in_subscribed_thread_email, email_recipients, post)
    end
  end

  def possible_recipients
    @possible_recipients ||= if post.broadcast_to_subscribers?
      subscribers = post.thread.subscribers

      if post.created_via_email?
        subscribers = subscribers.where.not(id: post.author)
      end

      subscribers.
        select { |u| Ability.new(u).can? :read, post }.
        to_set
    else
      Set.new
    end
  end
end
