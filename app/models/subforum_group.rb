class SubforumGroup < ActiveRecord::Base
  default_scope -> { order('ordinal ASC') }

  before_create do
    self.ordinal = self.class.count
  end
end
