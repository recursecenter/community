class AddMessageIdToPosts < ActiveRecord::Migration
  def up
    add_column :posts, :message_id, :string

    Post.all.each do |p|
      p.update_column :message_id, p.send(:generate_message_id)
    end

  end

  def down
    remove_column :posts, :message_id
  end
end
