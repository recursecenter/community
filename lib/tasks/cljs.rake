namespace :cljs do
  desc "Build your ClojureScript bundle for production"
  task :build do
    unless system "lein cljsbuild once production"
      raise "lein cljsbuild: ClojureScript build failed"
    end
  end

  namespace :build do
    desc "Build your ClojureScript bundle for testing"
    task :test do
      system "lein cljsbuild once test"
    end

    desc "Keep your ClojureScript bundle up to date"
    task :watch do
      Signal.trap "INT" do
        exit(0)
      end

      env = ENV["CLIENT_ENV"] || ENV["RAILS_ENV"] || "development"
      puts "Building ClojureScript for #{env}"
      system "lein cljsbuild auto #{env}"
    end
  end

  desc "Remove ClojureScript builds"
  task :clobber do
    rm_rf Dir["app/assets/builds/cljs*"], verbose: false
    system "lein clean"
  end
end

Rake::Task["assets:precompile"].enhance(["cljs:build"])
Rake::Task["assets:clobber"].enhance(["cljs:clobber"])
