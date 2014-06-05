class Post < ActiveRecord::Base
  belongs_to :thread, class_name: "DiscussionThread"
  belongs_to :author, class_name: "User"

  validates :body, :author, :thread, presence: {allow_blank: false}

  after_create -> do
    thread.update_last_post(self)
    thread.subforum.update_thread_last_posted_to(thread)
  end
end
