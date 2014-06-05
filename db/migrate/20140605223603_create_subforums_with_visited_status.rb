class CreateSubforumsWithVisitedStatus < ActiveRecord::Migration
  def change
    execute <<-SQL
      CREATE VIEW subforums_with_visited_status AS
        SELECT subforums.*, visited_statuses.last_visited, visited_statuses.user_id
          FROM subforums
          LEFT OUTER JOIN visited_statuses
            ON (subforums.id = visited_statuses.visitable_id)
          WHERE visited_statuses.visitable_type = 'Subforum'
            OR visited_statuses.visitable_type IS NULL;
    SQL
  end

  def down
    execute "DROP VIEW subforums_with_visited_status;"
  end
end
