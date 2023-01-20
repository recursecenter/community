namespace :cljs do
  desc "Build your ClojureScript bundle"
  task :build do
    unless system "lein cljsbuild once production"
      raise "lein cljsbuild: ClojureScript build failed"
    end
  end

  desc "Remove ClojureScript builds"
  task :clobber do
    rm_rf Dir["app/assets/builds/client_*"], verbose: false
    system "lein clean"
  end
end

Rake::Task["assets:precompile"].enhance(["cljs:build"])
Rake::Task["assets:clobber"].enhance(["cljs:clobber"])
