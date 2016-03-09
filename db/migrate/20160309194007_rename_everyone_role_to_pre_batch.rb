class RenameEveryoneRoleToPreBatch < ActiveRecord::Migration
  def up
    Role.where(name: 'everyone').update_all(name: 'pre_batch')
  end

  def down
    Role.where(name: 'pre_batch').update_all(name: 'everyone')
  end
end
