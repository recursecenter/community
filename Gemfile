source 'https://rubygems.org'

# When you update the Ruby version, make sure update and rebuild the Docker
# image in test/Dockerfile and update .circleci/config.yml.
ruby '3.1.3'

gem 'rails', '7.0.4.2'
gem 'pg'

gem 'bootsnap', require: false

gem 'redis'

gem 'dalli'
gem 'memcachier' # this just sets environmental variables

gem 'delayed_job_active_record'

# Disable until we're on a newer version of Ruby/Rails
# gem 'skylight'

# Attempt to work around https://github.com/airbrake/airbrake-ruby/issues/713
# by specifying verions of airbrake and airbrake-ruby which match what we're
# using on recurse.com.
gem 'airbrake', '13.0.2'
gem 'airbrake-ruby', '6.1.1'

# https://devcenter.heroku.com/articles/language-runtime-metrics-ruby
gem 'barnes'

# Use SCSS for stylesheets
gem 'sass-rails'
gem 'bootstrap-sass', '~> 3.4.1'
gem 'font-awesome-sass'

gem 'sprockets-rails'
gem 'sprockets'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

gem 'oauth2', '~> 1.4.11'
gem 'cancancan'

gem 'redcarpet'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
gem 'oj'

# bundle exec rake doc:rails generates the API under doc/api.
# gem 'sdoc', '~> 0.4.0',          group: :doc

gem 'pry-rails'

group :development do
  gem 'pry-remote'
  gem 'pry-doc'
  gem 'debug'
  gem 'web-console'
  gem 'listen'
end

group :development, :test do
  gem 'dotenv-rails'
  gem 'minitest-ci', git: 'https://github.com/circleci/minitest-ci.git'
end

# Use puma as the app server
gem 'puma'
gem 'faye-websocket'
gem 'rack-timeout'

gem 'bulk_insert'

gem 'concurrent-ruby'

gem 'pg_search'
gem 'kaminari'
