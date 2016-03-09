class RemoveUnusedAdminRole < ActiveRecord::Migration
  def up
    Role.where(name: 'admin').destroy_all
  end
end
