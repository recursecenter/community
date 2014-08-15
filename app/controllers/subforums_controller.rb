class SubforumsController < ApplicationController
  before_filter :require_login
  load_and_authorize_resource :subforum

  def unsubscribe
    subscription = current_user.subscriptions.where(subscribable: @subforum).first

    if subscription
      subscription.unsubscribe
    end

    render plain: "You've been unsubscribed from #{@subforum.subforum_group.name} > #{@subforum.name}."
  end
end
