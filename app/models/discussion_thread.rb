class DiscussionThread < ActiveRecord::Base
  belongs_to :subforum
  belongs_to :created_by, class_name: 'User'

  has_many :posts, foreign_key: "thread_id"
end
