class DiscussionThread < ActiveRecord::Base
  include DiscussionThreadCommon

  has_many :visited_statuses, as: :visitable

  validates :title, :created_by, :subforum, presence: {allow_blank: false}

  def update_last_post(post)
    update!(last_posted_to: post.created_at)
  end

  def mark_as_visited_for(user)
    status = visited_statuses.where(user_id: user.id).first_or_initialize
    status.update!(last_visited: DateTime.current)
  end
end
