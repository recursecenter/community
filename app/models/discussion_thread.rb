class DiscussionThread < ActiveRecord::Base
  include DiscussionThreadCommon
  include UnreadAndVisitable

  include Slug

  has_slug_for :title

  validates :title, :created_by, :subforum, presence: {allow_blank: false}
end
