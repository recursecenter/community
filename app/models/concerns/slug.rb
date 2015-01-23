module Slug
  extend ActiveSupport::Concern

  included do
    def self.has_slug_for(attribute)
      define_method :slug do
        self.send(attribute).downcase.gsub(/[^a-zA-Z0-9]/, " ").gsub(/\s+/, "-")
      end
    end
  end
end
