require_relative "boot"

# https://github.com/airbrake/airbrake-ruby/issues/713
require 'timeout'
Timeout.ensure_timeout_thread_created

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative "../lib/web_socket_handler"
require_relative "../lib/thread_error_logger"

module Community
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Not default, but recommended by the Configuring Rails
    # Applications guide.
    config.add_autoload_paths_to_load_path = false

    config.active_record.schema_format = :sql

    config.active_job.queue_adapter = :delayed_job

    config.action_controller.per_form_csrf_tokens = false

    config.middleware.use WebSocketHandler

    initializer('thread_error_logger', after: :load_config_initializers) do
      config.middleware.insert_before Airbrake::Rack::Middleware, ThreadErrorLogger
    end
  end
end
