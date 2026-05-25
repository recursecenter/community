ENV['RAILS_ENV'] = 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

# Minitest 6 removed the auto-call to Minitest.load_plugins from Minitest.run,
# so installed plugins (e.g. minitest-ci, which writes JUnit XML for CircleCI)
# never get loaded unless we call this explicitly.
Minitest.load_plugins

ENV['MAILGUN_API_KEY'] = "foobarbaz"

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

class ActionController::TestCase
  def login(user_name)
    session[:user_id] = users(user_name).id
  end
end
