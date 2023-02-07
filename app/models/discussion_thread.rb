class DiscussionThread < ActiveRecord::Base
  include DiscussionThreadCommon
  include Subscribable

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

  include Suggestable

  scope :possible_suggestions, ->(query) do
    return none if query.blank?

    terms = query.split.compact
    tsquery = terms.join(" <-> ") + ":*"

    where("to_tsvector('simple', title) @@ to_tsquery('simple', ?)", tsquery)
  end

  def suggestion_text
    title
  end

  # def self.suggest(user, query)
  #   suggestions(query).includes(:subforum).limit(5).select do |t|
  #     t.subforum.required_role_ids - user.role_ids == []
  #   end.map do |t|
  #     {
  #       "text" => t.title,
  #       "payload" => {
  #         "id" => t.id,
  #         "slug" => t.slug
  #       }
  #     }
  #   end
  end

  concerning :Searchable do
    def to_search_mapping
      thread_data = {
        suggest: {
          input: prefix_phrases(title),
          output: title,
          payload: {id: id, slug: slug, required_role_ids: subforum.required_role_ids}
        }
      }

      {index: {_id: id, data: thread_data}}
    end
  end
end
