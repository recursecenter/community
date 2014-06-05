class AddLastThreadPostedToToSubforums < ActiveRecord::Migration
  def up
    add_column :subforums, :last_thread_posted_to, :datetime

    Subforum.reset_column_information

    Subforum.all.each do |sf|
      sf.update!(last_thread_posted_to: sf.updated_at)
    end

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
    SQL
  end

  def down
    remove_column :subforums, :last_thread_posted_to

    execute <<-SQL
      DROP VIEW subforums_with_visited_status;

      CREATE VIEW subforums_with_visited_status AS
       SELECT subforums.id,
          subforums.name,
          subforums.subforum_group_id,
          subforums.created_at,
          subforums.updated_at,
          visited_statuses.last_visited,
          visited_statuses.user_id
         FROM (subforums
         LEFT JOIN visited_statuses ON ((subforums.id = visited_statuses.visitable_id)))
        WHERE (((visited_statuses.visitable_type)::text = 'Subforum'::text) OR (visited_statuses.visitable_type IS NULL));
    SQL
  end
end
