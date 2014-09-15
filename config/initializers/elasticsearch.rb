require 'elasticsearch/model'
ENV['ELASTICSEARCH_HOST'] ||= 'localhost'
ENV['ELASTICSEARCH_PORT'] ||= '9200'

enable_logging = Rails.env.development? ? true : false

Elasticsearch::Model.client = Elasticsearch::Client.new host: ENV['ELASTICSEARCH_HOST'], port: ENV['ELASTICSEARCH_PORT'], log: enable_logging
