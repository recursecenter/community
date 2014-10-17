class SubforumGroupIndexQuery < Query
  def initialize(user)
    @user = user
  end

  def relation
    groups_and_subforums
  end

private

  def groups_and_subforums
    subforums_by_group_id = subforums_with_recent_threads.group_by(&:subforum_group_id)
    groups = SubforumGroup.for_user(@user)

    groups.map { |g| [g, subforums_by_group_id[g.id]] }
  end

  def subforums_with_recent_threads
    # We can't just includes(:threads_with_visited_statuses) because
    # we need to limit the results, so we collect subforums and
    # threads separately and then associate them manually.

    subforums = Subforum.for_user(@user).with_counts

    from_sql = <<-SQL
      (
          SELECT *, row_number() OVER (PARTITION BY subforum_id ORDER BY last_post_created_at DESC) AS r
          FROM threads_with_visited_status
          WHERE user_id = #{@user.id} AND subforum_id IN (#{subforums.map(&:id).join(",")})
      ) threads_with_row_number
    SQL

    threads_by_subforum_id = ThreadWithVisitedStatus.
      select("threads_with_row_number.*").
      from(from_sql).
      where("threads_with_row_number.r <= 3").
      includes(:created_by, :last_post_created_by).
      group_by(&:subforum_id)

    subforums.map { |s| SubforumWithRecentThreads.new(s, threads_by_subforum_id[s.id]) }
  end
end
