class VisitedStatus < ActiveRecord::Base
  belongs_to :user
  belongs_to :thread, class_name: 'DiscussionThread'

  validates_uniqueness_of :user_id, scope: :thread_id
end
