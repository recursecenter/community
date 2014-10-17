class Post < ActiveRecord::Base
  belongs_to :thread, class_name: "DiscussionThread"
  belongs_to :author, class_name: "User"
  has_and_belongs_to_many :broadcast_groups, class_name: "Group"
  has_many :mentions, class_name: "Notifications::Mention", dependent: :destroy

  validates :body, :author, :thread, presence: {allow_blank: false}

  before_create :update_thread_data

  scope :by_number, -> { order(post_number: :asc) }

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

  def message_id
    format_message_id(thread_id, post_number)
  end

  def previous_message_id
    if post_number > 1
      format_message_id(thread_id, post_number-1)
    end
  end

private
  def format_message_id(thread_id, post_number)
    "<thread-#{thread_id}/post-#{post_number}@community.hackerschool.com>"
  end
end
