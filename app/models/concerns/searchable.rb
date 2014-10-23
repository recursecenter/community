module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    after_commit :upsert_to_search_index!

    RESULTS_PER_PAGE = 10

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
    def search(search_string, filters, page)
      __elasticsearch__.search(
        query: self.query_dsl(search_string, filters),
        highlight: self.highlight_fields,
        from: page * RESULTS_PER_PAGE,
        size: RESULTS_PER_PAGE
      )
    end

    # Suggest methods to return suggestions for this particular model
    def suggest(search_string)
       suggest = { suggestions: { text: search_string, completion: { field: "suggest" } } }
      __elasticsearch__.client.suggest(index: self.table_name, body: suggest)["suggestions"].first["options"]
    end

    # Override this method to customize the DSL for querying the including model
    def query_dsl(search_string, filters)
      return search_string
    end

    # Override this method to change the fields to highlight when this model is queried
    def highlight_fields
      return Hash.new
    end

    # Override this method in the corresponding model to enable allowed filter keys
    def allowed_filter_fields
      return Array.new
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
