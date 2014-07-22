class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.boolean :subscribed, default: false
      t.string :reason
      t.references :subscribable, index: true, polymorphic: true
      t.references :user

      t.timestamps
    end
  end
end
