class ThreadsController < ApplicationController
  before_filter :require_login
  load_and_authorize_resource :thread, class: 'DiscussionThread'

  def unsubscribe
    subscription = current_user.subscriptions.where(subscribable: @thread).first

    if subscription
      subscription.unsubscribe
    end

    render plain: "You've been unsubscribed from '#{@thread.title}.'"
  end

  def subscribe
    @thread.subscription_for(current_user).subscribe

    render plain: "You are receiving emails because you subscribed to this thread."
  end
end
