if Rails.env.production?
  Airbrake.configure do |config|
    config.project_id  = ENV['AIRBRAKE_PROJECT_ID']
    config.project_key = ENV['AIRBRAKE_PROJECT_KEY']

    config.blacklist_keys.push('password', 'password_confirmation', 'current_password', 'api_secret')
  end

  # Errors caused primarily by user error
  ignored_exceptions = [
    ActiveRecord::RecordNotFound,
    AbstractController::ActionNotFound,
    ActionController::InvalidAuthenticityToken,
    ActionController::UnknownFormat,
    ActionController::RoutingError,
  ]

  Airbrake.add_filter do |notice|
    notice.ignore! if notice.stash[:exception].class.in? ignored_exceptions
  end
end
