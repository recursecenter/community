class AddCreatorNameToThreadsWithVisitedStatus < ActiveRecord::Migration
  def up
    execute <<-SQL
      DROP VIEW threads_with_visited_status;

      CREATE VIEW threads_with_visited_status AS
       SELECT thread_users.*,
              CASE
                  WHEN (visited_statuses.last_post_number_read IS NULL) THEN 0
                  ELSE visited_statuses.last_post_number_read
              END AS last_post_number_read,
              CASE
                  WHEN (visited_statuses.last_post_number_read IS NULL) THEN true
                  ELSE (visited_statuses.last_post_number_read < thread_users.highest_post_number)
              END AS unread,
              (
                  SELECT users.first_name || ' ' || users.last_name
                  FROM posts
                  INNER JOIN users ON posts.author_id = users.id
                  WHERE posts.thread_id = thread_users.id
                  ORDER BY posts.post_number DESC
                  LIMIT 1
              ) AS last_author_name,
              (
                  SELECT first_name || ' ' || last_name
                  FROM users
                  WHERE thread_users.created_by_id = users.id
              ) AS creator_name
         FROM (( SELECT discussion_threads.*,
                  users.id AS user_id
                 FROM discussion_threads,
                  users) thread_users
           LEFT JOIN visited_statuses ON
            (((thread_users.id = visited_statuses.thread_id)
              AND
              ((thread_users.user_id = visited_statuses.user_id)
               OR
               (visited_statuses.user_id IS NULL)))));
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW threads_with_visited_status;

      CREATE VIEW threads_with_visited_status AS
       SELECT thread_users.*,
              CASE
                  WHEN (visited_statuses.last_post_number_read IS NULL) THEN 0
                  ELSE visited_statuses.last_post_number_read
              END AS last_post_number_read,
              CASE
                  WHEN (visited_statuses.last_post_number_read IS NULL) THEN true
                  ELSE (visited_statuses.last_post_number_read < thread_users.highest_post_number)
              END AS unread,
              (
                  SELECT users.first_name || ' ' || users.last_name
                  FROM posts
                  INNER JOIN users ON posts.author_id = users.id
                  WHERE posts.thread_id = thread_users.id
                  ORDER BY posts.post_number DESC
                  LIMIT 1
              ) AS last_author_name
         FROM (( SELECT discussion_threads.*,
                  users.id AS user_id
                 FROM discussion_threads,
                  users) thread_users
           LEFT JOIN visited_statuses ON
            (((thread_users.id = visited_statuses.thread_id)
              AND
              ((thread_users.user_id = visited_statuses.user_id)
               OR
               (visited_statuses.user_id IS NULL)))));
    SQL
  end
end
