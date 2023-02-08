class AddTsvToPosts < ActiveRecord::Migration[6.0]
  def up
    add_column :posts, :tsv, :tsvector
    add_index :posts, :tsv, using: :gin

    execute <<-SQL
      CREATE FUNCTION update_tsv_on_post() RETURNS trigger LANGUAGE plpgsql AS $$
        begin
          new.tsv := to_tsvector('pg_catalog.english', coalesce(new.body, ''));
          return new;
        end
      $$
    SQL

    execute <<-SQL
      CREATE TRIGGER update_tsv_on_post BEFORE INSERT OR UPDATE ON posts FOR EACH ROW EXECUTE FUNCTION update_tsv_on_post()
    SQL

    execute <<-SQL
      -- trigger the trigger for all posts
      UPDATE posts SET body = body
    SQL
  end

  def down
    execute <<-SQL
      DROP TRIGGER update_tsv_on_post ON posts
    SQL

    execute <<-SQL
      DROP FUNCTION update_tsv_on_post
    SQL

    remove_index :posts, :tsv
    remove_column :posts, :tsv, :tsvector
  end
end
