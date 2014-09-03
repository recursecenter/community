module SilenceDelayedJobQueries
  def reserve(*)
    previous_level = ::ActiveRecord::Base.logger.level
    ::ActiveRecord::Base.logger.level = Logger::WARN if previous_level < Logger::WARN
    super
  ensure
    ::ActiveRecord::Base.logger.level = previous_level
  end
end
