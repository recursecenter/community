namespace :search do
  desc "Rebuild search indexes from scratch for all search enabled models"
  task rebuild: :environment do
    [Post, DiscussionThread, Subforum, User].each(&:reset_search_index!)
  end
end
