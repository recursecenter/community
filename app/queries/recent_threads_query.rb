class RecentThreadsQuery < Query
  def initialize(subforum, user)
    @subforum = subforum
    @user = user
  end

  def each(&block)
    threads.map do |t|
      ThreadWithLastAuthor.new(t, last_author_for(t))
    end.each(&block)
  end

  private

  def last_author_for(thread)
    last_authors[thread.id]
  end

  def last_authors
    return @last_authors if defined? @last_authors

    ordered_post_sql = Post.select("*").
      joins(:author).
      where(thread_id: threads.map(&:id)).
      order(thread_id: :desc, post_number: :desc).
      to_sql

    results = execute <<-SQL
      SELECT ordered_posts.thread_id, first(ordered_posts.first_name || ' ' || ordered_posts.last_name) AS last_author_name
      FROM ( #{ordered_post_sql} ) AS ordered_posts
      GROUP BY ordered_posts.thread_id;
    SQL

    @last_authors = results.map do |row|
      [row["thread_id"], row["last_author_name"]]
    end.to_h
  end

  def threads
    @threads ||= @subforum.
      threads_for_user(@user).
      includes(:created_by).
      order(last_post_created_at: :desc).
      limit(3)
  end
end
