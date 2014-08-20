class SubforumGroup < ActiveRecord::Base
  default_scope -> { order('ordinal ASC') }

  has_many :subforums

  before_create do
    self.ordinal = self.class.count
  end
end
