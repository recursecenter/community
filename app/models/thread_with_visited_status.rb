class ThreadWithVisitedStatus < ActiveRecord::Base
  include PostgresView
  include DiscussionThreadCommon

  self.table_name = 'threads_with_visited_status'

  scope :for_user, ->(user) { where("user_id = ? OR user_id IS NULL", user.id) }

  def unread?
    last_visited.nil? || last_posted_to > last_visited
  end
end
