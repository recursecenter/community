class ChangeRequiredRolesToRequiredRole < ActiveRecord::Migration[6.0]
  def up
    if Subforum.where('cardinality(required_role_ids) != 1').exists?
      raise "All subforums must have a single required role"
    end

    add_reference :subforums, :required_role, foreign_key: {to_table: :roles}

    # Postgres arrays have 1-based indexing
    Subforum.update_all("required_role_id = required_role_ids[1]")

    remove_column :subforums, :required_role_ids
  end

  def down
    add_column :subforums, :required_role_ids, :integer, array: true

    Subforum.update_all("required_role_ids = ARRAY[required_role_id]")

    remove_reference :subforums, :required_role
  end
end
