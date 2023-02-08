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

  validates :name, uniqueness: {case_sensitive: false}
  validates :required_role_ids, length: {is: 1, message: "must have only one required role" }

  # we need to specify class_name because we want "thread" to be pluralized,
  # not "status".
  has_many :threads_with_visited_status, class_name: 'ThreadWithVisitedStatus'

  def threads_for_user(user)
    threads_with_visited_status.for_user(user)
  end

  include Suggestable

  scope :possible_suggestions, ->(query) do
    return none if query.blank?

    terms = query.split.compact
    tsquery = terms.join(" <-> ") + ":*"

    where("to_tsvector('simple', name) @@ to_tsquery('simple', ?)", tsquery)
  end

  def can_suggested_to_someone_with_role_ids?(role_ids)
    required_role_ids.to_set <= role_ids
  end

  def suggestion_text
    name
  end

#   concerning :Searchable do
#     def to_search_mapping
#       subforum_data = {
#         suggest: {
#           input: prefix_phrases(name),
#           output: name,
#           payload: {id: id, slug: slug, required_role_ids: self.required_role_ids}
#         }
#       }
#
#       {index: {_id: id, data: subforum_data}}
#     end
#   end
end
