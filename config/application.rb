require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require_relative '../lib/web_socket_handler'
require_relative '../lib/batch_mailgun_delivery_method'
require_relative '../lib/thread_error_logger'

module Community
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.

    config.active_record.schema_format = :sql

    config.active_job.queue_adapter = :delayed_job

    config.action_controller.per_form_csrf_tokens = false

    # Use a different logger for distributed setups.
    # require 'syslog/logger'
    # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

    if ENV["RAILS_LOG_TO_STDOUT"].present?
      logger           = ActiveSupport::Logger.new(STDOUT)
      logger.formatter = config.log_formatter
      config.logger    = ActiveSupport::TaggedLogging.new(logger)
    end

    config.middleware.use WebSocketHandler

    initializer('thread_error_logger', after: :load_config_initializers) do
      config.middleware.insert_before Airbrake::Rack::Middleware, ThreadErrorLogger
    end

    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.before_configuration do
      ActionMailer::Base.add_delivery_method :batch_mailgun, BatchMailgunDeliveryMethod
    end
  end
end

