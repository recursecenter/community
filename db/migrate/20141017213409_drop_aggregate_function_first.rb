class DropAggregateFunctionFirst < ActiveRecord::Migration
  def up
    execute <<-SQL
      DROP AGGREGATE first(anyelement);
      DROP FUNCTION first_of_two(anyelement, anyelement);
    SQL
  end

  def down
    execute <<-SQL
      --
      -- Name: first_of_two(anyelement, anyelement); Type: FUNCTION; Schema: public; Owner: -
      --

      CREATE FUNCTION first_of_two(anyelement, anyelement) RETURNS anyelement
          LANGUAGE sql IMMUTABLE STRICT
          AS $_$
                    SELECT $1;
            $_$;


      --
      -- Name: first(anyelement); Type: AGGREGATE; Schema: public; Owner: -
      --

      CREATE AGGREGATE first(anyelement) (
          SFUNC = first_of_two,
          STYPE = anyelement
      );
    SQL
  end
end
