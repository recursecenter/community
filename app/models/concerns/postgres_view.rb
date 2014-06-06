module PostgresView
  extend ActiveSupport::Concern

  included do
    # Postgres Views cannot have primary keys. Normally, attribute
    # methods are defined lazily, but we must do it explicitly so that
    # :id can be looked up as an attribute instead of as a primary
    # key, which fails.
    self.define_attribute_methods
  end
end
