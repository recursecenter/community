namespace :clojurescript do
  desc "Build your ClojureScript bundle"
  task :build do
    unless system "cd client && lein cljsbuild once production"
      raise "lein cljsbuild: ClojureScript build failed"
    end
  end
end

Rake::Task["assets:precompile"].enhance(["clojurescript:build"])
