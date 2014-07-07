class GroupMembership < ActiveRecord::Base
  belongs_to :user
  belongs_to :group

  scope :distinct_by_user_id, -> { select("DISTINCT ON (user_id) *") }
end
