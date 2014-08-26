class AddBroadcastToSubscribersToPosts < ActiveRecord::Migration
  def change
    add_column :posts, :broadcast_to_subscribers, :boolean, default: true
  end
end
