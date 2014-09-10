module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    after_commit :upsert_search_index!

    # Override this method to change the search mapping for this model
    def to_search_mapping
      { index: { _id: id, data: __elasticsearch__.as_indexed_json } }
    end

    # Insert/update a single row instance
    # TODO: Wrap it with begin-rescue
    def upsert_search_index!
      self.class.where(id: id).import transform: lambda {|item| item.to_search_mapping }
    end

    # Reset search index for the entire model 50 rows at a time
    def self.reset_search_index!
      self.import force: true, batch_size: 50, transform: lambda {|item| item.to_search_mapping }
    end

    def self.search_with_intent(query)
      #TODO: Do some complex query parsing and discover intent here
      self.search(query)
    end

  end
end