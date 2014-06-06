module UnreadAndVisitable
  extend ActiveSupport::Concern

  included do
    has_many :visited_statuses, as: :visitable

    def mark_unread_at(time)
      update!(marked_unread_at: time)
    end

    def mark_as_visited_for(user)
      status = visited_statuses.where(user_id: user.id).first_or_initialize
      status.update!(last_visited: DateTime.current)
    end
  end
end
