class Post < ActiveRecord::Base
  belongs_to :thread, class_name: "DiscussionThread"
  belongs_to :author, class_name: "User"

  validates :body, :author, :thread, presence: {allow_blank: false}

  after_create -> { thread.touch }
end
