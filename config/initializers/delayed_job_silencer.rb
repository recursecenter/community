if Rails.env.development?
  module SilenceDelayedJobQueries
    def reserve(*)
      previous_level = ::ActiveRecord::Base.logger.level
      ::ActiveRecord::Base.logger.level = Logger::WARN if previous_level < Logger::WARN
      value = super
      ::ActiveRecord::Base.logger.level = previous_level
      value
    end
  end

  class << Delayed::Backend::ActiveRecord::Job
    prepend SilenceDelayedJobQueries
  end
end
