require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative "../lib/web_socket_handler"

module Community
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

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
  end
end
