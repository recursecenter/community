class ThreadSubscriptionNotifierJob < ApplicationJob
  def perform(post, exclude_emails=[])
    ThreadSubscriptionNotifier.new(post).notify(exclude_emails=exclude_emails)
  end
end
