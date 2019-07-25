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

    config.active_record.schema_format = :sql

    config.active_job.queue_adapter = :delayed_job

    # Use a different logger for distributed setups.
    # require 'syslog/logger'
    # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

    if ENV["RAILS_LOG_TO_STDOUT"].present?
      logger           = ActiveSupport::Logger.new(STDOUT)
      logger.formatter = config.log_formatter
      config.logger    = ActiveSupport::TaggedLogging.new(logger)
    end

    config.middleware.use WebSocketHandler

    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end

require 'event_machine_smtp_delivery'
ActionMailer::Base.add_delivery_method :eventmachine_smtp, EventMachineSmtpDelivery
