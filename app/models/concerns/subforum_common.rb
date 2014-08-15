module SubforumCommon
  extend ActiveSupport::Concern

  included do
    has_many :threads, class_name: 'DiscussionThread'
    belongs_to :subforum_group
  end
end
