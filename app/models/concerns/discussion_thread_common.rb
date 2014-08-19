module DiscussionThreadCommon
  extend ActiveSupport::Concern

  included do
    belongs_to :subforum
    belongs_to :created_by, class_name: 'User'

    has_many :posts, foreign_key: "thread_id"
  end

  def required_roles
    subforum.required_roles
  end
end
