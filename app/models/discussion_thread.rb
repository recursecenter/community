class DiscussionThread < ActiveRecord::Base
  include DiscussionThreadCommon
  include Subscribable

  include Slug
  has_slug_for :title

  has_many :visited_statuses, foreign_key: 'thread_id'

  validates :title, :created_by, :subforum, presence: {allow_blank: false}

  def mark_post_as_visited(user, post)
    status = visited_statuses.where(user_id: user.id).first_or_initialize
    if post.post_number > status.last_post_number_read
      status.last_post_number_read = post.post_number
      status.save!
    end
  end

  def mark_as_visited(user)
    mark_post_as_visited(user, posts.last)
  end

  def resource_name
    "thread"
  end
end
