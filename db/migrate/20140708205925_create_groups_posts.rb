class CreateGroupsPosts < ActiveRecord::Migration
  def change
    create_table :groups_posts, id: false do |t|
      t.belongs_to :group
      t.belongs_to :post
    end
  end
end
