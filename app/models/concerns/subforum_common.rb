module SubforumCommon
  extend ActiveSupport::Concern

  included do
    has_many :threads, class_name: 'DiscussionThread'
    belongs_to :subforum_group
  end

  def required_roles
    Role.where(id: required_role_ids)
  end
end
