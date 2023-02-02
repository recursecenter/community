if Rails.env.production?
  Rack::Timeout.timeout = 30 # seconds
else
  Rack::Timeout.timeout = 30.days
end

Rack::Timeout::Logger.disable
