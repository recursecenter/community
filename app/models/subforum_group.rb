class SubforumGroup < ActiveRecord::Base
  default_scope -> { order('ordinal ASC') }

  has_many :subforums

  # we need to specify class_name because we want "subforum" to be pluralized,
  # not "status".
  has_many :subforums_with_visited_status, class_name: 'SubforumWithVisitedStatus'

  before_create do
    self.ordinal = self.class.count
  end

  def self.includes_subforums_for_user(user)
    self.includes(:subforums).
      references(:subforums).
      where("subforums.required_role_ids <@ '{?}'", user.role_ids).
      order("subforums.id ASC")
  end
end
