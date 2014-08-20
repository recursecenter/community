class VisitedStatus < ActiveRecord::Base
  belongs_to :user
  belongs_to :thread, class_name: 'DiscussionThread'

  validate :unique_for_thread_and_user, on: :create

  def unique_for_thread_and_user
    unless self.class.where(user_id: user_id, thread: thread).empty?
      errors[:base] << "There can be only one VisitedStatus for a given user and thread."
    end
  end
end
