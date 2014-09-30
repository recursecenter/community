namespace :search do
  desc "Rebuild search indexes from scratch for all search enabled models"
  task rebuild: :environment do
    Post.reset_search_index!
    DiscussionThread.reset_search_index!
    Subforum.reset_search_index!
    User.reset_search_index!
  end
end