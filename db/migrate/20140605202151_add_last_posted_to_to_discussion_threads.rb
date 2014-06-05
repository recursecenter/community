class AddLastPostedToToDiscussionThreads < ActiveRecord::Migration
  def up
    add_column :discussion_threads, :last_posted_to, :datetime

    DiscussionThread.reset_column_information

    DiscussionThread.all.each do |t|
      t.update(last_posted_to: t.updated_at)
    end
  end

  def down
    remove_column :discussion_threads, :last_posted_to
  end
end
