class NewThreadsQuery < Query
  def initialize(subforum, user)
    @subforum = subforum
    @user = user
  end

  def each(&block)
    threads.each(&block)
  end

  private

  def threads
    @subforum.
      threads_for_user(@user).
      order(last_post_created_at: :desc).
      limit(3)
  end
end
