class AddFirstAggregateFunction < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE FUNCTION first_of_two(anyelement, anyelement)
      RETURNS anyelement LANGUAGE sql IMMUTABLE STRICT AS '
              SELECT $1;
      ';

      CREATE AGGREGATE first (
              sfunc    = first_of_two,
              basetype = anyelement,
              stype    = anyelement
      );
    SQL
  end

  def down
    execute <<-SQL
      DROP AGGREGATE first(anyelement);
      DROP FUNCTION first_of_two(anyelement, anyelement);
    SQL
  end
end
