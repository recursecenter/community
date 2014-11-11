class Subforum < ActiveRecord::Base
  include Subscribable
  include SubforumCommon

  include Slug
  include Searchable
  has_slug_for :name

  scope :for_user, ->(user) do
    where("subforums.required_role_ids <@ '{?}'", user.role_ids)
  end

  scope :with_counts, -> do
    select <<-SQL
      subforums.*,
      (
          SELECT COUNT(*)
          FROM subscriptions
          WHERE subscribable_type = 'Subforum'
              AND subscribable_id = subforums.id
              AND subscribed = TRUE
      ) AS subscriber_count,
      (
          SELECT COUNT(*)
          FROM discussion_threads
          WHERE discussion_threads.subforum_id = subforums.id
      ) AS thread_count
    SQL
  end

  validates :name, uniqueness: { case_sensitive: false }

  # we need to specify class_name because we want "thread" to be pluralized,
  # not "status".
  has_many :threads_with_visited_status, class_name: 'ThreadWithVisitedStatus'

  def threads_for_user(user)
    threads_with_visited_status.for_user(user)
  end

  concerning :Searchable do
    def to_search_mapping
      subforum_data = {
        suggest: {
          input: prefix_phrases(name),
          output: name,
          payload: {id: id, slug: slug, required_role_ids: self.required_role_ids}
        }
      }

      { index: { _id: id, data: subforum_data } }
    end
  end
end
