class SubforumGroup < ActiveRecord::Base
  default_scope -> { order('ordinal ASC') }

  scope :includes_subforums_for_user, ->(user) do
    includes(:subforums).
      references(:subforums).
      merge(Subforum.for_user(user))
      order("subforums.id ASC")
  end

  scope :for_user, ->(user) do
    joins(:subforums).
      merge(Subforum.for_user(user))
      distinct
  end

  has_many :subforums

  before_create do
    self.ordinal = self.class.count
  end
end
