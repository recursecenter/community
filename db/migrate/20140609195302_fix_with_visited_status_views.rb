class FixWithVisitedStatusViews < ActiveRecord::Migration
  def up
    execute <<-SQL
      DROP VIEW subforums_with_visited_status;
      DROP VIEW threads_with_visited_status;

      CREATE VIEW subforums_with_visited_status AS
       SELECT subforum_users.*, visited_statuses.last_visited
       FROM (SELECT subforums.*, users.id AS user_id FROM subforums, users) AS subforum_users
         LEFT JOIN visited_statuses
           ON (subforum_users.id = visited_statuses.visitable_id
               AND (subforum_users.user_id = visited_statuses.user_id OR visited_statuses.user_id IS NULL)
               AND visited_statuses.visitable_type = 'Subforum');

      CREATE VIEW threads_with_visited_status AS
       SELECT thread_users.*, visited_statuses.last_visited
       FROM (SELECT discussion_threads.*, users.id AS user_id FROM discussion_threads, users) AS thread_users
         LEFT JOIN visited_statuses
           ON (thread_users.id = visited_statuses.visitable_id
               AND (thread_users.user_id = visited_statuses.user_id OR visited_statuses.user_id IS NULL)
               AND visited_statuses.visitable_type = 'DiscussionThread');
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW subforums_with_visited_status;
      DROP VIEW threads_with_visited_status;

      CREATE VIEW subforums_with_visited_status AS
       SELECT subforums.id,
          subforums.name,
          subforums.subforum_group_id,
          subforums.created_at,
          subforums.updated_at,
          subforums.marked_unread_at,
          visited_statuses.last_visited,
          visited_statuses.user_id
         FROM (subforums
         LEFT JOIN visited_statuses ON ((subforums.id = visited_statuses.visitable_id)))
        WHERE (((visited_statuses.visitable_type)::text = 'Subforum'::text) OR (visited_statuses.visitable_type IS NULL));

      CREATE VIEW threads_with_visited_status AS
       SELECT discussion_threads.id,
          discussion_threads.title,
          discussion_threads.subforum_id,
          discussion_threads.created_by_id,
          discussion_threads.created_at,
          discussion_threads.updated_at,
          discussion_threads.marked_unread_at,
          visited_statuses.last_visited,
          visited_statuses.user_id
         FROM (discussion_threads
         LEFT JOIN visited_statuses ON ((discussion_threads.id = visited_statuses.visitable_id)))
        WHERE (((visited_statuses.visitable_type)::text = 'DiscussionThread'::text) OR (visited_statuses.visitable_type IS NULL));
    SQL
  end
end
