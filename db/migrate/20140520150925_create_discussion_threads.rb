class CreateDiscussionThreads < ActiveRecord::Migration
  def change
    create_table :discussion_threads do |t|
      t.string :title
      t.references :subforum, index: true
      t.references :created_by, index: true

      t.timestamps
    end
  end
end
