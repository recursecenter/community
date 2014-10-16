class AddThreadIdIndexToPosts < ActiveRecord::Migration
  def change
    add_index :posts, :thread_id
  end
end
