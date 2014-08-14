module SubforumCommon
  extend ActiveSupport::Concern

  included do
    has_many :threads, class_name: 'DiscussionThread'
    belongs_to :subforum_group
    has_and_belongs_to_many :required_roles, class_name: 'Role'
  end
end
