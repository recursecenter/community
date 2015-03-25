namespace :accounts do
  desc "Import accounts from recurse.com"
  task import: :environment do
    AccountImporter.delay.import_all
  end
end
