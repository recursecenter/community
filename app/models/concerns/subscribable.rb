module Subscribable
  extend ActiveSupport::Concern

  included do
    has_many :subscriptions, as: :subscribable
  end

  def subscribers
    User.where(id: subscriptions.where(subscribed: true).select(:user_id))
  end

  def subscription_for(user)
    subscriptions.where(user_id: user).first_or_initialize do |s|
      s.subscribed = false
      s.reason = "You are not receiving emails because you are not subscribed."
    end
  end
end
