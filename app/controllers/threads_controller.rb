class ThreadsController < ApplicationController
  before_action :require_login, only: [:subscribe, :unsubscribe]
  before_action :require_reply_info, only: [:subscribe_with_reply_info, :unsubscribe_with_reply_info]

  load_and_authorize_resource :thread, class: 'DiscussionThread', only: [:subscribe, :unsubscribe]
  skip_authorization_check only: [:subscribe_with_reply_info, :unsubscribe_with_reply_info]

  def subscribe
    subscribe_and_render(current_user, @thread)
  end

  def unsubscribe
    unsubscribe_and_render(current_user, @thread)
  end

  def subscribe_with_reply_info
    user, post = reply_info
    subscribe_and_render(user, post.thread)
  end

  def unsubscribe_with_reply_info
    user, post = reply_info
    unsubscribe_and_render(user, post.thread)
  end

private
  def subscribe_and_render(user, thread)
    thread.subscription_for(user).subscribe

    render plain: "You've been subscribed to '#{thread.title}'."
  end

  def unsubscribe_and_render(user, thread)
    subscription = user.subscriptions.where(subscribable: thread).first

    if subscription
      subscription.unsubscribe
    end

    render plain: "You've been unsubscribed from '#{thread.title}'."
  end

  def require_reply_info
    unless reply_info
      render text: "404: Invalid link", status: 404
    end
  end

  def reply_info
    begin
      @reply_info ||= ReplyInfoVerifier.verify(params[:token])
    rescue ReplyInfoVerifier::InvalidSignature => e
      @reply_info = nil
    end
  end
end
