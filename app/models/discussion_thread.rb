class DiscussionThread < ActiveRecord::Base
  include DiscussionThreadCommon
  include UnreadAndVisitable

  validates :title, :created_by, :subforum, presence: {allow_blank: false}
end
