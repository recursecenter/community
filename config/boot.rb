ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

# https://github.com/airbrake/airbrake-ruby/issues/713
require 'timeout'
Timeout.ensure_timeout_thread_created

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
