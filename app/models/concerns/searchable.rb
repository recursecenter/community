module Searchable
  extend ActiveSupport::Concern

  # default number of results per page
  RESULTS_PER_PAGE = 25

  included do
    include Elasticsearch::Model
    after_commit :upsert_to_search_index!

    # Configure index to serve completion suggestions.
    settings index: { number_of_shards: 1 } do
      mappings dynamic: 'true' do
        indexes :suggest, type: :completion, index_analyzer: :whitespace, search_analyzer: :whitespace, payloads: true
      end
    end
  end

  module ClassMethods
    # Reset search index for the entire model 50 rows at a time
    def reset_search_index!
      import force: true, batch_size: 50, transform: lambda { |item| item.to_search_mapping }
    end

    # Search method to query the index for this particular model
    def search(user, search_string, filters, page, opts={})
      __elasticsearch__.search(
        opts.merge({
          query: generate_query(user, search_string, filters),
          highlight: highlight_fields,
          from: (page - 1) * RESULTS_PER_PAGE,
          size: RESULTS_PER_PAGE
        })
      )
    end

    # Suggest methods to return suggestions for this particular model
    def suggest(user, search_string)
      suggest_query = { suggestions: { text: search_string.downcase, completion: { field: "suggest" } } }

      suggestions = __elasticsearch__.client.suggest(index: table_name, body: suggest_query)["suggestions"]

      suggestions.first["options"].select do |suggestion|
        suggestion["payload"]["required_role_ids"] - user.role_ids == []
      end
    end

    # Override this method to customize the DSL for querying the including model
    def generate_query(user, search_string, filters)
      raise NotImplementedError, "You must define #{name}.generate_query(user, search_string, filters)"
    end

    # Override this method to change the fields to highlight when this model is queried
    def highlight_fields
      {}
    end
  end

  # Override this method to change the search mapping for the included model
  def to_search_mapping
    raise NotImplementedError, "You must define #{self.class.name}#to_search_mapping"
  end

  # Insert/update a single row instance
  def upsert_to_search_index!
    self.class.where(id: id).import transform: lambda { |item| item.to_search_mapping }
  end

private

  def prefix_phrases(s)
    words = s.downcase.split

    words.size.times.map do |i|
      words[i..-1].join(" ")
    end
  end
end
