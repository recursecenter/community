ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

# https://github.com/airbrake/airbrake-ruby/issues/713
require 'timeout'
Timeout.timeout(5) do
  sleep(1)
end

puts "!!!!!!!!!!!"
puts Thread.list.map { |t| "#{t} - #{t.group == ThreadGroup::Default ? "DEFAULT" : "no"}" }.join("\n")


require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

puts "+++++++++++"
puts Thread.list.map { |t| "#{t} - #{t.group == ThreadGroup::Default ? "DEFAULT" : "no"}" }.join("\n")
