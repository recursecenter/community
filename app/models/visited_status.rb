class VisitedStatus < ActiveRecord::Base
  belongs_to :user
  belongs_to :thread, class_name: 'DiscussionThread'

  validates_uniqueness_of :thread_id, scope: :user_id
end
