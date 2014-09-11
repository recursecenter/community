class AddLastPostCreatedAtToDiscussionThreads < ActiveRecord::Migration
  def up
    add_column :discussion_threads, :last_post_created_at, :datetime

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
    thread_users.user_id,
    thread_users.pinned,
    thread_users.last_post_created_at,
        CASE
            WHEN (visited_statuses.last_post_number_read IS NULL) THEN 0
            ELSE visited_statuses.last_post_number_read
        END AS last_post_number_read,
        CASE
            WHEN (visited_statuses.last_post_number_read IS NULL) THEN true
            ELSE (visited_statuses.last_post_number_read < thread_users.highest_post_number)
        END AS unread
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

    DiscussionThread.all.each do |t|
      t.update!(last_post_created_at: t.posts.order(post_number: :asc).last.created_at)
    end
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
    thread_users.user_id,
    thread_users.pinned,
        CASE
            WHEN (visited_statuses.last_post_number_read IS NULL) THEN 0
            ELSE visited_statuses.last_post_number_read
        END AS last_post_number_read,
        CASE
            WHEN (visited_statuses.last_post_number_read IS NULL) THEN true
            ELSE (visited_statuses.last_post_number_read < thread_users.highest_post_number)
        END AS unread
   FROM (( SELECT discussion_threads.id,
            discussion_threads.title,
            discussion_threads.subforum_id,
            discussion_threads.created_by_id,
            discussion_threads.created_at,
            discussion_threads.updated_at,
            discussion_threads.highest_post_number,
            discussion_threads.pinned,
            users.id AS user_id
           FROM discussion_threads,
            users) thread_users
   LEFT JOIN visited_statuses ON (((thread_users.id = visited_statuses.thread_id) AND ((thread_users.user_id = visited_statuses.user_id) OR (visited_statuses.user_id IS NULL)))));
SQL

    remove_column :discussion_threads, :last_post_created_at
  end
end
