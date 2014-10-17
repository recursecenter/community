class Subforum < ActiveRecord::Base
  include Subscribable
  include SubforumCommon

  include Slug
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
end
