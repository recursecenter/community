class SubforumsWithCountsQuery < Query
  def initialize(subforums, user)
    @subforums = subforums
    @user = user
  end

  def each(&block)
    select_sql = <<-SQL
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

    @subforums.
      select(select_sql).
      for_user(@user).
      each(&block)
  end
end
