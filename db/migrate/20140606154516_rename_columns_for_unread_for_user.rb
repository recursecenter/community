class RenameColumnsForUnreadForUser < ActiveRecord::Migration
  def up
    rename_column :discussion_threads, :last_posted_to, :marked_unread_at
    rename_column :subforums, :last_thread_posted_to, :marked_unread_at

    execute <<-SQL
      DROP VIEW subforums_with_visited_status;

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

      DROP VIEW threads_with_visited_status;

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

    DiscussionThread.reset_column_information
    Subforum.reset_column_information

    (DiscussionThread.all + Subforum.all).each do |x|
      x.update(marked_unread_at: x.updated_at)
    end
  end

  def down
    rename_column :discussion_threads, :marked_unread_at, :last_posted_to
    rename_column :subforums, :marked_unread_at, :last_thread_posted_to

    execute <<-SQL
      DROP VIEW subforums_with_visited_status;

      CREATE VIEW subforums_with_visited_status AS
       SELECT subforums.id,
          subforums.name,
          subforums.subforum_group_id,
          subforums.created_at,
          subforums.updated_at,
          subforums.last_thread_posted_to,
          visited_statuses.last_visited,
          visited_statuses.user_id
         FROM (subforums
         LEFT JOIN visited_statuses ON ((subforums.id = visited_statuses.visitable_id)))
        WHERE (((visited_statuses.visitable_type)::text = 'Subforum'::text) OR (visited_statuses.visitable_type IS NULL));

      DROP VIEW threads_with_visited_status;

      CREATE VIEW threads_with_visited_status AS
       SELECT discussion_threads.id,
          discussion_threads.title,
          discussion_threads.subforum_id,
          discussion_threads.created_by_id,
          discussion_threads.created_at,
          discussion_threads.updated_at,
          discussion_threads.last_posted_to,
          visited_statuses.last_visited,
          visited_statuses.user_id
         FROM (discussion_threads
         LEFT JOIN visited_statuses ON ((discussion_threads.id = visited_statuses.visitable_id)))
        WHERE (((visited_statuses.visitable_type)::text = 'DiscussionThread'::text) OR (visited_statuses.visitable_type IS NULL));
    SQL

  end
end
