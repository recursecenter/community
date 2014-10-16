class OptimizeThreadsWithVisitedStatusesQuery < ActiveRecord::Migration
  def up
    execute <<-SQL
DROP VIEW threads_with_visited_status;

CREATE VIEW threads_with_visited_status AS
(
 SELECT thread_users.*,
        visited_statuses.last_post_number_read,
        (visited_statuses.last_post_number_read < thread_users.highest_post_number) AS unread,
    ( SELECT (((users.first_name)::text || ' '::text) || (users.last_name)::text)
       FROM (posts JOIN users ON (posts.author_id = users.id))
      WHERE (posts.thread_id = thread_users.id)
      ORDER BY posts.post_number DESC
     LIMIT 1) AS last_author_name,
    ( SELECT (((users.first_name)::text || ' '::text) || (users.last_name)::text)
       FROM users
      WHERE (thread_users.created_by_id = users.id)) AS creator_name
   FROM (( SELECT discussion_threads.*, users.id AS user_id
           FROM discussion_threads,
            users) thread_users
   INNER JOIN visited_statuses ON
    (thread_users.id = visited_statuses.thread_id AND thread_users.user_id = visited_statuses.user_id))
)
UNION
(
 SELECT thread_users.*,
        0 AS last_post_number_read,
        TRUE AS unread,
    ( SELECT (((users.first_name)::text || ' '::text) || (users.last_name)::text)
       FROM (posts JOIN users ON (posts.author_id = users.id))
      WHERE (posts.thread_id = thread_users.id)
      ORDER BY posts.post_number DESC
     LIMIT 1) AS last_author_name,
    ( SELECT (((users.first_name)::text || ' '::text) || (users.last_name)::text)
       FROM users
      WHERE (thread_users.created_by_id = users.id)) AS creator_name
   FROM ( SELECT discussion_threads.*, users.id AS user_id FROM discussion_threads, users) thread_users
   LEFT JOIN visited_statuses ON thread_users.id = visited_statuses.thread_id AND thread_users.user_id = visited_statuses.user_id
   WHERE visited_statuses.id IS NULL
);
    SQL
  end

  def down
    execute <<-SQL
DROP VIEW threads_with_visited_status;

CREATE VIEW threads_with_visited_status AS
 SELECT thread_users.id,
    thread_users.title,
    thread_users.subforum_id,
    thread_users.created_by_id,
    thread_users.created_at,
    thread_users.updated_at,
    thread_users.highest_post_number,
    thread_users.pinned,
    thread_users.last_post_created_at,
    thread_users.user_id,
        CASE
            WHEN (visited_statuses.last_post_number_read IS NULL) THEN 0
            ELSE visited_statuses.last_post_number_read
        END AS last_post_number_read,
        CASE
            WHEN (visited_statuses.last_post_number_read IS NULL) THEN true
            ELSE (visited_statuses.last_post_number_read < thread_users.highest_post_number)
        END AS unread,
    ( SELECT (((users.first_name)::text || ' '::text) || (users.last_name)::text)
           FROM (posts
      JOIN users ON ((posts.author_id = users.id)))
     WHERE (posts.thread_id = thread_users.id)
     ORDER BY posts.post_number DESC
    LIMIT 1) AS last_author_name,
    ( SELECT (((users.first_name)::text || ' '::text) || (users.last_name)::text)
           FROM users
          WHERE (thread_users.created_by_id = users.id)) AS creator_name
   FROM (( SELECT discussion_threads.id,
            discussion_threads.title,
            discussion_threads.subforum_id,
            discussion_threads.created_by_id,
            discussion_threads.created_at,
            discussion_threads.updated_at,
            discussion_threads.highest_post_number,
            discussion_threads.pinned,
            discussion_threads.last_post_created_at,
            users.id AS user_id
           FROM discussion_threads,
            users) thread_users
   LEFT JOIN visited_statuses ON (((thread_users.id = visited_statuses.thread_id) AND ((thread_users.user_id = visited_statuses.user_id) OR (visited_statuses.user_id IS NULL)))));
    SQL
  end
end
