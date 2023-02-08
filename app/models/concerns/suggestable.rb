module Suggestable
  extend ActiveSupport::Concern

  class_methods do
    def suggest(user, query)
      role_ids = user.role_ids.to_set

      possible_suggestions(query).
        select { |s| s.can_suggested_to_someone_with_role_ids?(role_ids) }.
        take(5).
        map { |s| Suggestion.new(s) }
    end
  end

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
end
