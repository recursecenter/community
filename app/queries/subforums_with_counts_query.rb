class SubforumsWithCountsQuery < Query
  def initialize(subforums)
    @subforums = subforums
  end

  def each(&block)
    @subforums.select(<<-SQL).each(&block)
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
end
