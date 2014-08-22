class DatabaseForker
  attr_reader :base_name

  def initialize(base_name)
    @base_name = base_name
  end

  def current_branch
    `git rev-parse --abbrev-ref HEAD`.chomp
  end

  def fork_name
    "#{base_name}-#{current_branch}"
  end

  def has_fork?
    Rails.env.development? && system("echo '\q' | psql -d #{fork_name} 2>/dev/null")
  end

  def database_name
    if has_fork?
      fork_name
    else
      base_name
    end
  end

  def fork!
    system("createdb -O `whoami` -T #{base_name} #{fork_name}")
  end

  def drop_fork!
    system("dropdb #{fork_name}")
  end

  def forks(conn)
    res = nil

    silence_stream(STDOUT) do
      res = conn.exec_query("SELECT datname FROM pg_database WHERE datname LIKE '#{base_name}-%';")
    end

    res.rows.map(&:first)
  end
end
