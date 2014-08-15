class AddSubscribeNewThreadInSubscribedSubforumToUser < ActiveRecord::Migration
  def change
    add_column :users, :subscribe_new_thread_in_subscribed_subforum, :boolean, default: true
  end
end
