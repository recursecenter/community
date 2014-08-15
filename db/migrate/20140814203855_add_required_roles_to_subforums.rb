class AddRequiredRolesToSubforums < ActiveRecord::Migration
  def change
    add_column :subforums, :required_role_ids, :integer, array: true
  end
end
