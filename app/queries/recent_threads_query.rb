class RecentThreadsQuery < Query
  def initialize(subforum, user)
    @subforum = subforum
    @user = user
  end

  def each(&block)
    threads.each(&block)
  end

  private

  def threads
    @threads ||= @subforum.
      threads_for_user(@user).
      includes(:created_by, :last_post_created_by).
      order(last_post_created_at: :desc).
      limit(3)
  end
end
