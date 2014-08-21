class AddPostNumberToPostsAndHighestPostNumberToDiscussionThreads < ActiveRecord::Migration
  def up
    add_column :posts, :post_number, :integer
    add_column :discussion_threads, :highest_post_number, :integer, default: 0

    DiscussionThread.all.each do |thread|
      thread.update(highest_post_number: thread.posts.count)
      thread.posts.order(created_at: :asc).each_with_index do |post, i|
        post.update(post_number: i+1)
      end
    end
  end

  def down
    remove_column :posts, :post_number
    remove_column :discussion_threads, :highest_post_number
  end
end
