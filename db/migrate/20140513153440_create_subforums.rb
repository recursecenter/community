class CreateSubforums < ActiveRecord::Migration
  def change
    create_table :subforums do |t|
      t.string :name
      t.references :subforum_group

      t.timestamps
    end
  end
end
