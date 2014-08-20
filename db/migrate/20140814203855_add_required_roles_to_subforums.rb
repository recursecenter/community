class AddRequiredRolesToSubforums < ActiveRecord::Migration
  def change
    add_column :subforums, :required_role_ids, :integer, array: true

    Subforum.all.each do |subforum|
      subforum.update(required_role_ids: [Role.everyone])
    end
  end
end
