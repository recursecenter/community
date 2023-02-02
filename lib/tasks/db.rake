namespace :db do
  desc "Pull production data"
  task :pull do
    sh "dropdb community_development"
    sh "heroku pg:pull DATABASE community_development"
  end
end
