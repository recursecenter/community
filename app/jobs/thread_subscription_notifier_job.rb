class ThreadSubscriptionNotifierJob < ApplicationJob
  def perform(post, exclude_emails: [])
    ThreadSubscriptionNotifier.new(post, exclude_emails: exclude_emails).notify
  end
end
