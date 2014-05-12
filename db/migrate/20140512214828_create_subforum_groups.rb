class CreateSubforumGroups < ActiveRecord::Migration
  def change
    create_table :subforum_groups do |t|
      t.string :name, null: false
      t.integer :ordinal, null: false

      t.timestamps
    end
  end
end
