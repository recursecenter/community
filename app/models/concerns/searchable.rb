module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    after_commit :upsert_to_search_index!

    settings index: { number_of_shards: 1 } do
      mappings dynamic: 'true' do
        indexes :suggest, type: :completion, index_analyzer: :simple, search_analyzer: :simple, payloads: true
      end
    end
  end

  module ClassMethods
    # Reset search index for the entire model 50 rows at a time
    def reset_search_index!
      self.import force: true, batch_size: 50, transform: lambda { |item| item.to_search_mapping }
    end

    # Search method to query the index for this particular model
    def search(query)
      __elasticsearch__.search(query: self.query_dsl(query), highlight: self.highlight_fields)
    end

    # Suggest methods to return suggestions for this particular model
    def suggest(query)
       suggest = { suggestions: { text: query, completion: { field: "suggest" } } }
      __elasticsearch__.client.suggest(index: self.table_name, body: suggest)["suggestions"].first["options"]
    end

    # Override this method to customize the DSL for querying the including model
    def query_dsl(query)
      return strip_filters(query)
    end

    # Override this method to change the fields to highlight when this model is queried
    def highlight_fields
      return Hash.new
    end

    # Override this method in the corresponding model to enable allowed filter keys
    def allowed_filter_fields
      return Array.new
    end

    # For every allowed filter key,
    # return key-value pairs for patterns matching "key:(value)" pattern.
    # value can have spaces.
    def filters(query)
      filters = Hash.new
      allowed_filter_fields.each do |filter_key|
        matches = /(?<key>#{filter_key}):\((?<value>[^\)]*)\)/.match(query)
        filters[matches[:key]] = matches[:value] unless matches.blank?
      end
      return filters
    end

    # Removes all filters from query and just return plain query
    def strip_filters(query)
      matches = /(([A-Za-z_]+):\(([^\)]+)\) )+(?<text>.*)/.match(query)
      if filters(query).blank? && matches.blank?
        return query
      else
        return matches[:text]
      end
    end
  end

  module InstanceMethods
    # Override this method to change the search mapping for this model
    def to_search_mapping
      { index: { _id: id, data: __elasticsearch__.as_indexed_json } }
    end

    # Insert/update a single row instance
    def upsert_to_search_index!
      self.class.where(id: id).import transform: lambda { |item| item.to_search_mapping }
    end
  end
end
