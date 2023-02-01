source 'https://rubygems.org'

# When you update the Ruby version, make sure update and rebuild the Docker
# image in test/Dockerfile and update .circleci/config.yml.
ruby '2.6.10'

gem 'rails', '6.0.6.1'
gem 'pg'

# Remove this when we upgrade to Ruby 3.1 or later.
gem 'mail', '~> 2.7.1'

gem 'bootsnap', require: false

gem 'redis'

gem 'dalli'
gem 'memcachier' # this just sets environmental variables

gem 'delayed_job_active_record'

# Disable until we're on a newer version of Ruby/Rails
# gem 'skylight'
gem 'airbrake'

# https://devcenter.heroku.com/articles/language-runtime-metrics-ruby
gem 'barnes'

# Use SCSS for stylesheets
gem 'sass-rails'
gem 'bootstrap-sass', '~> 3.4.1'
gem 'font-awesome-sass'

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
  gem 'pry-byebug'
  gem 'web-console'
  gem 'listen'
end

group :development, :test do
  gem 'dotenv-rails'
  gem 'minitest-ci', git: 'https://github.com/circleci/minitest-ci.git'
end

# Use puma as the app server
gem 'puma', '~> 5.6'
gem 'faye-websocket'
gem 'rack-timeout'

gem 'bulk_insert'

gem 'concurrent-ruby'

gem 'elasticsearch', '~> 2.0'
gem 'elasticsearch-model', '~> 2.0'
gem 'elasticsearch-rails', '~> 2.0'
