# TODO:
# This should be called something like UnreadTracking::ForModels (with a better name)
module UnreadAndVisitable
  extend ActiveSupport::Concern

  included do
    has_many :visited_statuses, foreign_key: 'thread_id'

    before_create -> { self.marked_unread_at ||= Time.zone.now }
  end

  def mark_unread_at(time)
    update!(marked_unread_at: time)
  end

  def mark_as_visited_for(user)
    status = visited_statuses.where(user_id: user.id).first_or_initialize
    status.last_visited = DateTime.current
    status.save!
  end
end
