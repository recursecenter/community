if Rails.env.production?
  Airbrake.configure do |config|
    config.project_id  = ENV['AIRBRAKE_PROJECT_ID']
    config.project_key = ENV['AIRBRAKE_PROJECT_KEY']

    config.blacklist_keys.push('password', 'password_confirmation', 'current_password', 'api_secret')

    config.root_directory = Rails.root
    config.environment = Rails.env
  end

  Airbrake.add_filter do |notice|
    # Errors caused primarily by user error
    ignored_exceptions = [
      ActiveRecord::RecordNotFound,
      AbstractController::ActionNotFound,
      ActionController::InvalidAuthenticityToken,
      ActionController::UnknownFormat,
      ActionController::RoutingError,
    ]

    notice.ignore! if notice.stash[:exception].class.in? ignored_exceptions
  end
end
