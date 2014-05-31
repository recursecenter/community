workers Integer(ENV['PUMA_WORKERS'] || 1)
threads Integer(ENV['MIN_THREADS']  || 1), Integer(ENV['MAX_THREADS'] || 1)

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     or raise 'Please set ENV["PORT"]'
environment ENV['RACK_ENV'] || 'development'

on_worker_boot do
  # worker specific setup
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end

  uri = URI.parse(ENV["REDIS_URL"])
  $redis = Redis.new(host: uri.host, port: uri.port, password: uri.password)
end
