class AddSubscribeOnCreateAndSubscribeWhenMentionedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :subscribe_on_create, :boolean, default: true
    add_column :users, :subscribe_when_mentioned, :boolean, default: true
  end
end
