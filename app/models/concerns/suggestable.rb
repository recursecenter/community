module Suggestable
  extend ActiveSupport::Concern

  class Suggestion
    attr_reader :suggestable

    def initialize(suggestable)
      @suggestable = suggestable
    end

    def as_json
      json = {
        "text" => suggestable.suggestion_text,
        "payload" => {
          "id" => suggestable.id
        }
      }

      if suggestable.respond_to?(:slug)
        json["payload"]["slug"] = suggestable.slug
      end

      json
    end
  end

  class_methods do
    def suggest(user, query)
      possible_suggestions(query).limit(5).accessable_by(user).map do |suggestable|
        Suggestion.new(suggestable)
      end
    end
  end
end
