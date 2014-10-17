class AddLastPostCreatedByToDiscussionThreads < ActiveRecord::Migration
  def up
    add_reference :discussion_threads, :last_post_created_by, index: true

    DiscussionThread.all.each do |t|
      t.update_column(:last_post_created_by_id, t.posts.by_number.last.author.id)
    end

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
            thread_users.last_post_created_by_id,
            thread_users.user_id,
            visited_statuses.last_post_number_read,
            (visited_statuses.last_post_number_read < thread_users.highest_post_number) AS unread
           FROM (( SELECT discussion_threads.id,
                    discussion_threads.title,
                    discussion_threads.subforum_id,
                    discussion_threads.created_by_id,
                    discussion_threads.created_at,
                    discussion_threads.updated_at,
                    discussion_threads.highest_post_number,
                    discussion_threads.pinned,
                    discussion_threads.last_post_created_at,
                    discussion_threads.last_post_created_by_id,
                    users.id AS user_id
                   FROM discussion_threads,
                    users) thread_users
      JOIN visited_statuses ON (((thread_users.id = visited_statuses.thread_id) AND (thread_users.user_id = visited_statuses.user_id))))
UNION
         SELECT thread_users.id,
            thread_users.title,
            thread_users.subforum_id,
            thread_users.created_by_id,
            thread_users.created_at,
            thread_users.updated_at,
            thread_users.highest_post_number,
            thread_users.pinned,
            thread_users.last_post_created_at,
            thread_users.last_post_created_by_id,
            thread_users.user_id,
            0 AS last_post_number_read,
            true AS unread
           FROM (( SELECT discussion_threads.id,
                    discussion_threads.title,
                    discussion_threads.subforum_id,
                    discussion_threads.created_by_id,
                    discussion_threads.created_at,
                    discussion_threads.updated_at,
                    discussion_threads.highest_post_number,
                    discussion_threads.pinned,
                    discussion_threads.last_post_created_at,
                    discussion_threads.last_post_created_by_id,
                    users.id AS user_id
                   FROM discussion_threads,
                    users) thread_users
      LEFT JOIN visited_statuses ON (((thread_users.id = visited_statuses.thread_id) AND (thread_users.user_id = visited_statuses.user_id))))
     WHERE (visited_statuses.id IS NULL);
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
            visited_statuses.last_post_number_read,
            (visited_statuses.last_post_number_read < thread_users.highest_post_number) AS unread
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
      JOIN visited_statuses ON (((thread_users.id = visited_statuses.thread_id) AND (thread_users.user_id = visited_statuses.user_id))))
UNION
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
            0 AS last_post_number_read,
            true AS unread
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
      LEFT JOIN visited_statuses ON (((thread_users.id = visited_statuses.thread_id) AND (thread_users.user_id = visited_statuses.user_id))))
     WHERE (visited_statuses.id IS NULL);
    SQL

    remove_column :discussion_threads, :last_post_created_by_id
  end
end
