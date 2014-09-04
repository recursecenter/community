class AddDescriptionToSubforums < ActiveRecord::Migration
  def change
    add_column :subforums, :description, :text
  end
end
