class Subforum < ActiveRecord::Base
  has_many :threads, class_name: 'DiscussionThread'

  include UnreadAndVisitable

  include Slug

  has_slug_for :name

  # we need to specify class_name because we want "thread" to be pluralized,
  # not "status".
  has_many :threads_with_visited_status, class_name: 'ThreadWithVisitedStatus'

  def threads_for_user(user)
    threads_with_visited_status.for_user(user)
  end
end
