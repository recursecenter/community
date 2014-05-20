class DiscussionThread < ActiveRecord::Base
  belongs_to :subforum
  belongs_to :created_by, class_name: 'User'
end
