class AddThreadIdIndexToVisitedStatuses < ActiveRecord::Migration
  def change
    add_index :visited_statuses, :thread_id
  end
end
