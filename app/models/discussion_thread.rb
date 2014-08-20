class DiscussionThread < ActiveRecord::Base
  include DiscussionThreadCommon
  include Subscribable

  include Slug
  has_slug_for :title

  has_many :visited_statuses, foreign_key: 'thread_id'

  validates :title, :created_by, :subforum, presence: {allow_blank: false}

  def mark_as_visited_for(user, post)
    status = visited_statuses.where(user_id: user.id).first_or_initialize
    status.last_post_number_read = post.post_number
    status.save!
  end

  def resource_name
    "thread"
  end
end
