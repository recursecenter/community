namespace :accounts do
  desc "Import accounts from recurse.com"
  task import: :environment do
    AccountImporter.delay.import_all
  end

  desc "Deactivate accounts that have been deactivated on recurse.com"
  task sync_deactivated_accounts: :environment do
    AccountImporter.delay.sync_deactivated_accounts
  end
end
