class RecentThreadsQuery < Query
  def initialize(subforum, user)
    @subforum = subforum
    @user = user
  end

  def each(&block)
    threads.map do |t|
      ThreadWithLastAuthor.new(t, creator_for(t), last_author_for(t))
    end.each(&block)
  end

  private

  def creator_for(thread)
    creators[thread.id]
  end

  def last_author_for(thread)
    last_authors[thread.id]
  end

  def creators
    return @creators if defined? @creators

    creator_map = User.select(:id, :first_name, :last_name).where(id: threads.map(&:created_by_id)).map do |u|
      [u.id, u]
    end.to_h

    @creators = threads.map do |t|
      [t.id, creator_map[t.created_by_id].name]
    end.to_h
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
      order(last_post_created_at: :desc).
      limit(3)
  end
end
