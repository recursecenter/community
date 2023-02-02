class ThreadWithVisitedStatus < ActiveRecord::Base
  self.table_name = 'threads_with_visited_status'
  self.primary_key = 'id'

  include DiscussionThreadCommon

  include Slug
  has_slug_for :title

  scope :for_user, ->(user) { where(user_id: user.id) }

  def subscribers
    User.where(id: Subscription.where(subscribed: true, subscribable_id: id, subscribable_type: 'DiscussionThread').select(:user_id))
  end

  def next_unread_post_number
    if unread? && !last_post_number_read.zero?
      last_post_number_read + 1
    end
  end

  def readonly?
    true
  end
end
