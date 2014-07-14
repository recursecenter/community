module Subscribable
  extend ActiveSupport::Concern

  included do
    has_many :subscriptions, as: :subscribable
    has_many :subscribers, through: :subscriptions, source: 'user'
  end

  def subscription_for(user)
    subscriptions.where(user_id: user).first_or_initialize do |s|
      s.subscribed = false
      s.reason = "You are not receiving emails because you are not subscribed."
    end
  end
end
