class Post < ActiveRecord::Base
  belongs_to :thread, class_name: "DiscussionThread"
  belongs_to :author, class_name: "User"
  has_and_belongs_to_many :broadcast_groups, class_name: "Group"
  has_many :mentions, class_name: "Notifications::Mention", dependent: :destroy

  validates :body, :author, :thread, presence: {allow_blank: false}

  before_create :update_thread_data
  before_create :set_message_id

  scope :by_number, -> { order(post_number: :asc) }

  MAX_WORDS_IN_HIGHLIGHT = 35

  include PgSearch::Model
  pg_search_scope :search,
                  against: :body,
                  using: {
                    tsearch: {
                      dictionary: "english",
                      tsvector_column: "tsv",
                      highlight: {
                        StartSel: "<span class='highlight'>",
                        StopSel: "</span>",
                        MaxWords: MAX_WORDS_IN_HIGHLIGHT,
                      }
                    }
                  }

  scope :with_null_pg_search_highlight, -> do
    select("posts.*", "ts_headline('english', posts.body, to_tsquery('english', ''), 'MaxWords=#{MAX_WORDS_IN_HIGHLIGHT}') AS pg_search_highlight")
  end

  scope :author_named, ->(author_name) do
    users = User.where("users.first_name || ' ' || users.last_name = ?", author_name)

    where(author_id: users)
  end

  scope :for_user, ->(user) do
    joins(:thread).where(discussion_threads: {subforum_id: Subforum.for_user(user)})
  end

  def update_thread_data
    DistributedLock.new("thread_#{thread.id}").synchronize do
      next_post_number = thread.highest_post_number + 1
      self.post_number = next_post_number
      thread.update(highest_post_number: next_post_number,
                    last_post_created_at: created_at,
                    last_post_created_by: author)
    end
  end

  def required_roles
    thread.subforum.required_roles
  end

  def mark_as_visited(user)
    thread.mark_post_as_visited(user, self)
  end

  def previous_post
    thread.posts.where(post_number: post_number - 1).first
  end

  def previous_message_id
    if post_number > 1
      previous_post.message_id
    end
  end

  def created_via_email?
    unless message_id
      raise "Post#created_via_email? only works on persisted posts"
    end

    message_id != generate_message_id
  end

private
  def format_message_id(thread_id, post_number)
    "<thread-#{thread_id}/post-#{post_number}@community.recurse.com>"
  end

  def set_message_id
    # message_id will already be set if the post was created by email
    self.message_id ||= generate_message_id
  end

  def generate_message_id
    format_message_id(thread_id, post_number)
  end
end
