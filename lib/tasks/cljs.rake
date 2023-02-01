require 'clojure_script'

namespace :cljs do
  desc "Build your ClojureScript bundle"
  task :build do
    puts "Building ClojureScript for #{ClojureScript.env}"
    unless system "lein cljsbuild once #{ClojureScript.env}"
      raise "lein cljsbuild: ClojureScript build failed"
    end
  end

  namespace :build do
    desc "Build your ClojureScript test bundle"
    task :test do
      system({"RAILS_ENV" => "test"}, "rails cljs:build", exception: true)
    end

    # To run tests in the browser, jasmine needs to load application.js, so
    # we have to precompile it. See jasmine-browser.json. We don't want to
    # just use assets:precompile, because that will create public/assets
    # which Rails will use from then on in development, instead of compiling
    # assets on demand.
    task test_assets: :environment do
      assets = Rails.application.assets
      manifest = Sprockets::Manifest.new(assets.cached, "test/assets/builds")
      manifest.compile("application.js")
    end
  end

  desc "Keep your ClojureScript bundle up to date"
  task :watch do
    puts "Building ClojureScript for #{ClojureScript.env}"
    exec "lein cljsbuild auto #{ClojureScript.env}"
  end

  namespace :watch do
    desc "Keep your ClojureScript test bundle up to date"
    task test: "build:test_assets" do
      exec({"RAILS_ENV" => "test"}, "rails cljs:watch")
    end
  end

  desc "Run the ClojureScript tests"
  task test: "build:test_assets" do
    system("yarn run test", exception: true)
  end

  desc "Remove ClojureScript builds"
  task :clobber do
    rm_rf Dir["app/assets/builds/**/*"], verbose: false
    rm_rf Dir["test/assets/builds/**/*"], verbose: false
    system "lein clean", exception: true
  end
end

# In CI, we build the ClojureScript source in a separate
# Docker image, so we don't want assets:precompile to
# attempt to build ClojureScript too.
unless ENV["CI"]
  Rake::Task["assets:precompile"].enhance(["cljs:build"])
end

Rake::Task["assets:clobber"].enhance(["cljs:clobber"])
