# TODO:
# This should be called something like UnreadTracking::ForViews (with a better name)
module UnreadForUser
  extend ActiveSupport::Concern

  included do
    scope :for_user, ->(user) { where(user_id: user.id) }
  end

  def unread?
    last_visited.nil? || marked_unread_at > last_visited
  end
end
