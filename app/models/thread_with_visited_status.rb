class ThreadWithVisitedStatus < ActiveRecord::Base
  self.table_name = 'threads_with_visited_status'
  self.primary_key = 'id'

  include PostgresView
  include DiscussionThreadCommon

  include Slug
  has_slug_for :title

  scope :for_user, ->(user) { where(user_id: user.id) }

  def unread?
    self.unread
  end
end
