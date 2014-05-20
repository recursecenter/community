class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.text :body
      t.references :thread
      t.references :author

      t.timestamps
    end
  end
end
