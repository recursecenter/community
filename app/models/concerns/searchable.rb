module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
    after_commit :upsert_to_search_index!

    # Reset search index for the entire model 50 rows at a time
    def self.reset_search_index!
      self.import force: true, batch_size: 50, transform: lambda {|item| item.to_search_mapping }
    end

    def self.search(query)
      #TODO: Do some complex query parsing and discover intent here
      __elasticsearch__.search(query).results
    end
  end

  # Override this method to change the search mapping for this model
  def to_search_mapping
    { index: { _id: id, data: __elasticsearch__.as_indexed_json } }
  end

  # Insert/update a single row instance
  # TODO: Wrap it with begin-rescue
  def upsert_to_search_index!
    self.class.where(id: id).import transform: lambda {|item| item.to_search_mapping }
  end
end
