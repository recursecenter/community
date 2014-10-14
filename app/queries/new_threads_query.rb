class NewThreadsQuery < Query
  def initialize(subforum, user)
    @subforum = subforum
    @user = user
  end

  def each(&block)
    threads.map do |t|
      ThreadWithLastAuthor.new(t, author_for(t))
    end.each(&block)
  end

  private

  def threads
    @threads ||= @subforum.
      threads_for_user(@user).
      includes(:created_by).
      order(last_post_created_at: :desc).
      limit(3)
  end

  def author_for(thread)
    author_names[thread.id]
  end

  def author_names
    return @author_names if defined?(@author_names)

    ordered_post_sql = Post.select("*").
      joins(:author).
      where(thread_id: threads.map(&:id)).
      order(thread_id: :desc, post_number: :desc).
      to_sql

    results = execute <<-SQL
      SELECT ordered_posts.thread_id, first(ordered_posts.first_name || ' ' || ordered_posts.last_name) AS last_author_name
      FROM (
          #{ordered_post_sql}
      ) AS ordered_posts
      GROUP BY ordered_posts.thread_id;
    SQL

    @author_names = results.map do |row|
      [row["thread_id"], row["last_author_name"]]
    end.to_h
  end
end
