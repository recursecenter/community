class Post < ActiveRecord::Base
  belongs_to :thread, class_name: "DiscussionThread"
  belongs_to :author, class_name: "User"
  has_and_belongs_to_many :broadcast_groups, class_name: "Group"
  has_many :mentions, class_name: "Notifications::Mention"

  validates :body, :author, :thread, presence: {allow_blank: false}

  before_create :add_and_increment_post_number
  after_create :mark_thread_as_read

  def add_and_increment_post_number
    DistributedLock.new("thread_#{thread.id}").synchronize do
      next_post_number = thread.highest_post_number + 1
      self.post_number = next_post_number
      thread.update(highest_post_number: next_post_number)
    end
  end

  def mark_thread_as_read
    thread.mark_unread_at(self.created_at)
  end

  def required_roles
    thread.subforum.required_roles
  end
end
