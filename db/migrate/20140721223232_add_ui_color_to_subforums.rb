class AddUiColorToSubforums < ActiveRecord::Migration
  def up
    add_column :subforums, :ui_color, :string

    execute <<-SQL
DROP VIEW subforums_with_visited_status;

CREATE VIEW subforums_with_visited_status AS
 SELECT subforum_users.id,
    subforum_users.name,
    subforum_users.subforum_group_id,
    subforum_users.ui_color,
    subforum_users.created_at,
    subforum_users.updated_at,
    subforum_users.marked_unread_at,
    subforum_users.user_id,
    visited_statuses.last_visited
   FROM (( SELECT subforums.id,
            subforums.name,
            subforums.ui_color,
            subforums.subforum_group_id,
            subforums.created_at,
            subforums.updated_at,
            subforums.marked_unread_at,
            users.id AS user_id
           FROM subforums,
            users) subforum_users
   LEFT JOIN visited_statuses ON ((((subforum_users.id = visited_statuses.visitable_id) AND ((subforum_users.user_id = visited_statuses.user_id) OR (visited_statuses.user_id IS NULL))) AND ((visited_statuses.visitable_type)::text = 'Subforum'::text))));
SQL
  end

  def down
    remove_column :subforums, :ui_color

    execute <<-SQL
DROP VIEW subforums_with_visited_status;

CREATE VIEW subforums_with_visited_status AS
 SELECT subforum_users.id,
    subforum_users.name,
    subforum_users.subforum_group_id,
    subforum_users.created_at,
    subforum_users.updated_at,
    subforum_users.marked_unread_at,
    subforum_users.user_id,
    visited_statuses.last_visited
   FROM (( SELECT subforums.id,
            subforums.name,
            subforums.subforum_group_id,
            subforums.created_at,
            subforums.updated_at,
            subforums.marked_unread_at,
            users.id AS user_id
           FROM subforums,
            users) subforum_users
   LEFT JOIN visited_statuses ON ((((subforum_users.id = visited_statuses.visitable_id) AND ((subforum_users.user_id = visited_statuses.user_id) OR (visited_statuses.user_id IS NULL))) AND ((visited_statuses.visitable_type)::text = 'Subforum'::text))));
SQL
  end
end
