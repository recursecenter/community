class ThreadWithVisitedStatus < ActiveRecord::Base
  self.table_name = 'threads_with_visited_status'
  self.primary_key = 'id'

  include PostgresView
  include DiscussionThreadCommon
  include UnreadForUser

  include Slug

  has_slug_for :title
end
