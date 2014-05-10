worker_processes Integer(ENV["WEB_CONCURRENCY"] || 1)
timeout 15
preload_app true

if ENV["RACK_ENV"] == "development"
  timeout 30 * 60 * 60 * 24 # 30 days, max timeout
else
  timeout 30
end

before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end
