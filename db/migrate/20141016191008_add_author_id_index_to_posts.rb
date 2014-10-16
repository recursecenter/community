class AddAuthorIdIndexToPosts < ActiveRecord::Migration
  def change
    add_index :posts, :author_id
  end
end
