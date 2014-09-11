class Post < ActiveRecord::Base
  include Searchable

  belongs_to :thread, class_name: "DiscussionThread"
  belongs_to :author, class_name: "User"
  has_and_belongs_to_many :broadcast_groups, class_name: "Group"
  has_many :mentions, class_name: "Notifications::Mention", dependent: :destroy

  validates :body, :author, :thread, presence: {allow_blank: false}

  before_create :add_and_increment_post_number

  def add_and_increment_post_number
    DistributedLock.new("thread_#{thread.id}").synchronize do
      next_post_number = thread.highest_post_number + 1
      self.post_number = next_post_number
      thread.update(highest_post_number: next_post_number)
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

  def to_search_mapping
    {
      index: {
        _id: id,
        data: {
          body: body,
          author: author.id,
          author_name: author.first_name,
          author_email: author.email,
          thread: thread.id,
          thread_title: thread.title,
          post_number: post_number,
          subforum: thread.subforum.id,
          subforum_name: thread.subforum.name,
          subforum_group: thread.subforum.subforum_group.id,
          subforum_group_name: thread.subforum.subforum_group.name,
          ui_color: thread.subforum.ui_color
        }
      }
    }
  end

private
  def format_message_id(thread_id, post_number)
    "<thread-#{thread_id}/post-#{post_number}@community.hackerschool.com>"
  end
end