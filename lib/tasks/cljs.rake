module ClojureScript
  def self.env
    ENV["CLJS_ENV"] || ENV["CLIENT_ENV"] || ENV["RAILS_ENV"] || "development"
  end
end

namespace :cljs do
  desc "Build your ClojureScript bundle for"
  task :build do
    unless system "lein cljsbuild once #{ClojureScript.env}"
      raise "lein cljsbuild: ClojureScript build failed"
    end
  end

  desc "Keep your ClojureScript bundle up to date"
  task :watch do
    puts "Building ClojureScript for #{ClojureScript.env}"
    exec "lein cljsbuild auto #{ClojureScript.env}"
  end

  desc "Remove ClojureScript builds"
  task :clobber do
    rm_rf Dir["app/assets/builds/**/*"], verbose: false
    system "lein clean"
  end
end

Rake::Task["assets:precompile"].enhance(["cljs:build"])
Rake::Task["assets:clobber"].enhance(["cljs:clobber"])
