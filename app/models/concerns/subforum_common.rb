module SubforumCommon
  extend ActiveSupport::Concern

  included do
    has_many :threads, class_name: 'DiscussionThread'
  end
end
