class OneRolePerSubforum < ActiveRecord::Migration
  def up
    Subforum.where("required_role_ids = ARRAY[1, 2]").update_all(required_role_ids: [2])
  end

  def down
    Subforum.where("required_role_ids = ARRAY[2]").update_all(required_role_ids: [1, 2])
  end
end
