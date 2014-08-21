require 'database_forker'

namespace :db do
  desc "Fork database for the current branch"
  task :fork do
    forker = DatabaseForker.new("community_development")

    if forker.has_fork?
      puts "#{forker.fork_name} already exists. Run `bin/rake db:fork:drop` to drop it."
    elsif forker.fork!
      system("bin/spring stop >/dev/null")
      puts "#{forker.fork_name} forked from #{forker.base_name}. Remember to restart foreman."
    else
      puts "There was an error while forking #{forker.base_name}"
    end
  end

  namespace :fork do
    desc "Lists all current database forks"
    task list: :environment do
      forker = DatabaseForker.new("community_development")

      puts forker.forks(ActiveRecord::Base.connection)
    end

    desc "Drops the fork for the current branch if it exists"
    task :drop do
      forker = DatabaseForker.new("community_development")

      if forker.has_fork?
        if forker.drop_fork!
          system("bin/spring stop >/dev/null")
          puts "Dropped #{forker.fork_name}"
        else
          puts "There was an error while dropping #{forker.fork_name}."
        end
      else
        puts "#{forker.fork_name} doesn't exist."
      end
    end
  end
end
