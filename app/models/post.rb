class Post < ActiveRecord::Base
  belongs_to :thread, class_name: "DiscussionThread"
  belongs_to :author, class_name: "User"

  validates :body, :author, :thread, presence: {allow_blank: false}

  after_create -> do
    thread.mark_unread_at(self.created_at)
    thread.subforum.mark_unread_at(thread.marked_unread_at)
  end
end
