class DiscussionThread < ActiveRecord::Base
  belongs_to :subforum
  belongs_to :created_by, class_name: 'User'

  has_many :posts, foreign_key: "thread_id"

  has_many :visited_statuses, as: :visitable

  validates :title, :created_by, :subforum, presence: {allow_blank: false}

  def update_last_post(post)
    update!(last_posted_to: post.created_at)
  end

  def mark_as_visited_for(user)
    status = visited_statuses.where(user_id: user.id).first_or_initialize
    status.update!(last_visited: DateTime.current)
  end

  def unread_for?(user)
    status = visited_statuses.where(user_id: user.id).first

    if status
      last_posted_to > status.last_visited
    else
      true
    end
  end
end
