class NonPolymorphicVisitedStatuses < ActiveRecord::Migration
  def up
    add_column :visited_statuses, :thread_id, :integer

    VisitedStatus.all.each do |vs|
      if vs.visitable_type == 'DiscussionThread'
        vs.update_columns(thread_id: vs.visitable_id)
      end
    end

    execute <<-SQL
DROP VIEW threads_with_visited_status;

CREATE VIEW threads_with_visited_status AS
 SELECT thread_users.*, visited_statuses.last_visited
   FROM (( SELECT discussion_threads.*, users.id AS user_id
           FROM discussion_threads,
            users) thread_users
   LEFT JOIN visited_statuses ON (((thread_users.id = visited_statuses.thread_id) AND ((thread_users.user_id = visited_statuses.user_id) OR (visited_statuses.user_id IS NULL)))));
    SQL

    change_table :visited_statuses do |t|
      t.remove_references :visitable, polymorphic: true
    end
  end

  def down
    change_table :visited_statuses do |t|
      t.references :visitable, index: true, polymorphic: true
    end

    VisitedStatus.all.each do |vs|
      vs.update_columns(visitable_id: vs.thread_id, visitable_type: 'DiscussionThread')
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
    thread_users.marked_unread_at,
    thread_users.user_id,
    visited_statuses.last_visited
   FROM (( SELECT discussion_threads.id,
            discussion_threads.title,
            discussion_threads.subforum_id,
            discussion_threads.created_by_id,
            discussion_threads.created_at,
            discussion_threads.updated_at,
            discussion_threads.marked_unread_at,
            users.id AS user_id
           FROM discussion_threads,
            users) thread_users
   LEFT JOIN visited_statuses ON ((((thread_users.id = visited_statuses.visitable_id) AND ((thread_users.user_id = visited_statuses.user_id) OR (visited_statuses.user_id IS NULL))) AND ((visited_statuses.visitable_type)::text = 'DiscussionThread'::text))));
    SQL

    remove_column :visited_statuses, :thread_id
  end
end
