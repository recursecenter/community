class Subforum < ActiveRecord::Base
  include Subscribable
  include SubforumCommon

  include Slug
  has_slug_for :name

  validates :name, uniqueness: true

  # we need to specify class_name because we want "thread" to be pluralized,
  # not "status".
  has_many :threads_with_visited_status, class_name: 'ThreadWithVisitedStatus'

  def threads_for_user(user)
    threads_with_visited_status.for_user(user)
  end
end
