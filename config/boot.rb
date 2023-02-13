ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.

# https://github.com/airbrake/airbrake-ruby/issues/713
require 'timeout'
Timeout.ensure_timeout_thread_created

require "bootsnap/setup" # Speed up boot time by caching expensive operations.
