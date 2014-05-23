class Subforum < ActiveRecord::Base
  has_many :threads, class_name: 'DiscussionThread'

  default_scope -> { includes(:threads) }
end
