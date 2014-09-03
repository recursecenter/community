require 'delayed_job_class_reloader'
require 'silence_delayed_job_queries'

Delayed::Worker.delay_jobs = !Rails.env.test?
Delayed::Worker.destroy_failed_jobs = false

unless Rails.application.config.cache_classes
  Delayed::Worker.plugins << DelayedJobClassReloader
end

if Rails.env.development?
  class << Delayed::Backend::ActiveRecord::Job
    prepend SilenceDelayedJobQueries
  end
end
