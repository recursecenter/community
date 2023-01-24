class ThreadErrorLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue ThreadError => e
    puts "=== ThreadErrorLogger: Caught ThreadError ==="
    puts "Thread.list.size = #{Thread.list.size}"
    puts

    Thread.list.each do |t|
      puts "=== #{t} backtrace ==="
      puts t.backtrace
    end

    puts "=== ThreadErrorLogger: done ==="

    raise e
  end
end
