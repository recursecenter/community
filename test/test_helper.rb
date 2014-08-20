ENV['RAILS_ENV'] = 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

uri = URI.parse(ENV["REDIS_URL"])
$redis = Redis.new(host: uri.host, port: uri.port, password: uri.password)

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

class MockRedis
  def publish(feed, data)
  end
end
