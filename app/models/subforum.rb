class Subforum < ActiveRecord::Base
  include Subscribable
  include SubforumCommon

  include Slug
  include Searchable
  has_slug_for :name

  # we need to specify class_name because we want "thread" to be pluralized,
  # not "status".
  has_many :threads_with_visited_status, class_name: 'ThreadWithVisitedStatus'

  def threads_for_user(user)
    threads_with_visited_status.for_user(user)
  end

  def to_search_mapping
    subforum_data = Hash.new
    subforum_data["suggest"] = {
      input: [name.split(" ")],
      output: name,
      payload: {id: id, slug: slug}
    }

    { index: { _id: id, data: subforum_data } }
  end
end
