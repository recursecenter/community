class ThreadSubscriptionNotifierJob < ApplicationJob
  def perform(post)
    ThreadSubscriptionNotifier.new(post).notify
  end
end
