require 'silence_delayed_job_queries'

Delayed::Worker.delay_jobs = !Rails.env.test?
Delayed::Worker.destroy_failed_jobs = false

if Rails.env.development?
  class << Delayed::Backend::ActiveRecord::Job
    prepend SilenceDelayedJobQueries
  end
end
