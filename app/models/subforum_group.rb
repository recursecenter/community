class SubforumGroup < ActiveRecord::Base
  default_scope -> { order('ordinal ASC') }

  scope :includes_subforums_for_user, ->(user) do
    includes(:subforums).
      references(:subforums).
      where("subforums.required_role_ids <@ '{?}'", user.role_ids).
      order("subforums.id ASC")
  end

  scope :for_user, ->(user) do
    joins(:subforums).
      where("subforums.required_role_ids <@ '{?}'", user.role_ids).
      uniq
  end

  has_many :subforums

  before_create do
    self.ordinal = self.class.count
  end
end
