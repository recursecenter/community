namespace :accounts do

  desc "Import accounts from hackerschool.com"
  task import: :environment do
    # TODO: put this on a job queue
    AccountImporter.new.delay.import_all
  end

end
