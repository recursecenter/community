require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative '../lib/web_socket_handler'

module Community
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.active_record.schema_format = :sql

    config.active_job.queue_adapter = :delayed_job

    config.middleware.use WebSocketHandler
  end
end

require 'event_machine_smtp_delivery'
ActionMailer::Base.add_delivery_method :eventmachine_smtp, EventMachineSmtpDelivery
