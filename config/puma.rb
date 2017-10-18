threads_count = Integer(ENV['RAILS_MAX_THREADS'] || 1)

workers Integer(ENV['WEB_CONCURRENCY'] || 1)
threads threads_count, threads_count

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     or raise 'Please set ENV["PORT"]'
environment ENV['RACK_ENV'] || 'development'

quiet

before_fork do
  ActiveRecord::Base.connection.disconnect!
end

on_worker_boot do
  # worker specific setup
  ActiveSupport.on_load(:active_record) do
    Rails.logger.error "Worker booted. #{ConnectionMonitor::CONNECTIONS.size} checked out connections."
    config = ActiveRecord::Base.configurations[Rails.env] ||
                Rails.application.config.database_configuration[Rails.env]

    config['reaping_frequency'] = 8
    ActiveRecord::Base.establish_connection(config)
  end
end

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart
