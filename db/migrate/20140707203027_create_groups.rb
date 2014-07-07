class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :name
      t.integer :hacker_school_batch_id
      t.timestamps
    end

    create_table :group_memberships do |t|
      t.belongs_to :group
      t.belongs_to :user
      t.timestamps
    end
  end
end
