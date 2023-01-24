module ClojureScript
  def self.env
    ENV["CLJS_ENV"] || ENV["CLIENT_ENV"] || ENV["RAILS_ENV"] || "development"
  end
end

namespace :cljs do
  desc "Build your ClojureScript bundle"
  task :build do
    unless system "lein cljsbuild once #{ClojureScript.env}"
      raise "lein cljsbuild: ClojureScript build failed"
    end
  end

  namespace :build do
    desc "Build your ClojureScript test bundle"
    task :test do
      system({"RAILS_ENV" => "test"}, "rails assets:precompile", exception: true)
    end
  end

  desc "Keep your ClojureScript bundle up to date"
  task :watch do
    puts "Building ClojureScript for #{ClojureScript.env}"
    exec "lein cljsbuild auto #{ClojureScript.env}"
  end

  namespace :watch do
    desc "Keep your ClojureScript test bundle up to date"
    task :test do
      # Why CI => true? Because we're building for cljs:test, we'll
      # need to precompile application.js, but we don't want to trigger
      # a one-off cljs:build just do spin up another JVM to do a test
      # build again in cljs:watch.
      system({"RAILS_ENV" => "test", "CI" => "true"}, "rails assets:precompile", exception: true)
      exec({"RAILS_ENV" => "test"}, "rails cljs:watch")
    end
  end

  desc "Run the ClojureScript tests"
  task :test do
    system("yarn run test", exception: true)
  end

  desc "Remove ClojureScript builds"
  task :clobber do
    rm_rf Dir["app/assets/builds/**/*"], verbose: false
    rm_rf Dir["test/clojurescript/builds/**/*"], verbose: false
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
