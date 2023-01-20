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
      system({"RAILS_ENV" => "test"}, "rails cljs:build")
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
      exec({"RAILS_ENV" => "test"}, "rails cljs:watch")
    end
  end

  desc "Run the ClojureScript tests"
  task :test do
    system("yarn run test")
  end

  desc "Remove ClojureScript builds"
  task :clobber do
    rm_rf Dir["app/assets/builds/**/*"], verbose: false
    rm_rf Dir["test/clojurescript/builds/**/*"], verbose: false
    system "lein clean"
  end
end

Rake::Task["assets:precompile"].enhance(["cljs:build"])
Rake::Task["assets:clobber"].enhance(["cljs:clobber"])
