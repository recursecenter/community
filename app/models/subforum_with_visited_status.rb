class SubforumWithVisitedStatus < ActiveRecord::Base
  self.table_name = 'subforums_with_visited_status'

  include PostgresView
  include UnreadForUser

  include Slug

  has_slug_for :name
end
