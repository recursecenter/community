EM.error_handler do |e|
  Rails.logger.error "Error raised in event loop: #{e.class.name}: #{e.message}"
  Rails.logger.error e.backtrace.join("\n")
end
