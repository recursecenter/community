class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.string :type
      t.references :user, index: true
      t.references :mentioned_by, index: true
      t.references :post, index: true
      t.boolean :read, default: false

      t.timestamps
    end
  end
end
