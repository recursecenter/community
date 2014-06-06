class SubforumWithVisitedStatus < ActiveRecord::Base
  self.table_name = 'subforums_with_visited_status'

  include PostgresView

  scope :for_user, ->(user) { where("user_id = ? OR user_id IS NULL", user.id) }

  def unread?
    last_visited.nil? || marked_unread_at > last_visited
  end
end
