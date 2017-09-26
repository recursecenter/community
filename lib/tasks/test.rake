require 'rake/testtask'

namespace :test do
  task :run => ['test:units', 'test:functionals', 'test:generators', 'test:integration', 'test:services']

  Rake::TestTask.new(services: "test:prepare") do |t|
    t.pattern = 'test/services/**/*_test.rb'
  end
end
