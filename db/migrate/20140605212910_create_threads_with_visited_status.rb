class CreateThreadsWithVisitedStatus < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE VIEW threads_with_visited_status AS
        SELECT discussion_threads.*, visited_statuses.last_visited, visited_statuses.user_id
          FROM discussion_threads
          LEFT OUTER JOIN visited_statuses
            ON (discussion_threads.id = visited_statuses.visitable_id)
          WHERE visited_statuses.visitable_type = 'DiscussionThread'
            OR visited_statuses.visitable_type IS NULL;
    SQL
  end

  def down
    execute "DROP VIEW threads_with_visited_status;"
  end
end
