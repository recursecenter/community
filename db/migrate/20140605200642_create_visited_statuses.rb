class CreateVisitedStatuses < ActiveRecord::Migration
  def change
    create_table :visited_statuses do |t|
      t.references :user, index: true
      t.datetime :last_visited
      t.references :visitable, index: true, polymorphic: true

      t.timestamps
    end
  end
end
