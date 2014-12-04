workers Integer(ENV['PUMA_WORKERS'] || 1)
threads Integer(ENV['MIN_THREADS']  || 1), Integer(ENV['MAX_THREADS'] || 1)

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     or raise 'Please set ENV["PORT"]'
environment ENV['RACK_ENV'] || 'development'

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
