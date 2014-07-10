class DiscussionThread < ActiveRecord::Base
  include DiscussionThreadCommon
  include UnreadAndVisitable

  include Slug

  has_slug_for :title

  validates :title, :created_by, :subforum, presence: {allow_blank: false}

  has_many :subscriptions, as: :subscribable

  def resource_name
    "thread"
  end

  def subscription_for(user)
    subscriptions.where(user_id: user).first_or_initialize do |s|
      s.subscribed = false
      s.reason = "You are not receiving emails because you are not subscribed."
    end
  end
end
