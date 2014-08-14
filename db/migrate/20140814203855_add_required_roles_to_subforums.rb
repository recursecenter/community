class AddRequiredRolesToSubforums < ActiveRecord::Migration
  def change
    create_join_table :subforums, :roles do |t|
      t.index :subforum_id
      t.index :role_id
    end
  end
end
