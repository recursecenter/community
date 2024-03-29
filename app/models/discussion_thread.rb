class DiscussionThread < ActiveRecord::Base
  include DiscussionThreadCommon
  include Subscribable
  include Suggestable

  include Slug
  has_slug_for :title

  has_many :visited_statuses, foreign_key: 'thread_id'

  validates :title, :created_by, :subforum, presence: {allow_blank: false}

  def mark_post_as_visited(user, post)
    DistributedLock.new("visited_status_#{user.id}_#{post.thread.id}").synchronize do
      status = visited_statuses.where(user_id: user.id).first_or_initialize
      if post.post_number > status.last_post_number_read
        status.last_post_number_read = post.post_number
        status.save
      end
    end
  end

  def mark_as_visited(user)
    mark_post_as_visited(user, posts.last)
  end

  def resource_name
    "thread"
  end

  concerning :Suggestable do
    included do
      scope :possible_suggestions, ->(query) do
        return none if query.blank?

        terms = query.split.compact
        tsquery = terms.join(" <-> ") + ":*"

        where("to_tsvector('simple', title) @@ to_tsquery('simple', ?)", tsquery).includes(:subforum)
      end
    end

    def can_suggested_to_someone_with_role_ids?(role_ids)
      subforum.required_role_ids.to_set <= role_ids
    end

    def suggestion_text
      title
    end
  end
end
