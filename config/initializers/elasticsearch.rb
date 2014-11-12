ENV['ELASTICSEARCH_URL'] ||= ENV['BONSAI_URL'] || 'http://localhost:9200'

Elasticsearch::Model.client = Elasticsearch::Client.new log: Rails.env.development?
