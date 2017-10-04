namespace :search do
  desc "Create emtpy search indexes"
  task create_indexes: :environment do
    [Post, DiscussionThread, Subforum, User].each do |klass|
      klass.__elasticsearch__.client.indices.create \
        index: klass.index_name,
        body: { settings: klass.settings.to_hash, mappings: klass.mappings.to_hash }
    end
  end

  desc "Rebuild search indexes from scratch for all search enabled models"
  task rebuild: :environment do
    [Post, DiscussionThread, Subforum, User].each(&:reset_search_index!)
  end
end
