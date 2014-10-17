class SubforumGroupIndexQuery < Query
  def initialize(user)
    @user = user
  end

  def relation
    subforum_groups
  end

  private

  def subforum_groups
    groups = SubforumGroup.for_user(@user)
    subforums = Subforum.for_user(@user).with_counts

    subforums_by_group_id = subforums.group_by(&:subforum_group_id)

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

    subforums.each do |sf|
      threads = threads_by_subforum_id[sf.id]

      association = sf.association(:threads_with_visited_status)
      association.loaded!
      association.target.concat(threads)
      threads.each { |t| association.set_inverse_instance(t) }
    end

    groups.map { |g| [g, subforums_by_group_id[g.id]] }
  end
end
