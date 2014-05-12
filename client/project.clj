(defproject community "0.1.0-SNAPSHOT"
  :dependencies [[org.clojure/clojure "1.5.1"]
                 [org.clojure/clojurescript "0.0-2202"]
                 [org.clojure/core.async "0.1.303.0-886421-alpha"]
                 [om "0.6.2"]
                 [cljs-ajax "0.2.4"]]

  :plugins [[lein-cljsbuild "1.0.3"]]

  :cljsbuild {
    :builds [{:id "community-dev"
              :source-paths ["src"]
              :compiler {:output-to "../app/assets/javascripts/client-dev.js"
                         :output-dir "../app/assets/javascripts/client-dev"
                         :optimizations :none
                         :pretty-print true
                         :source-map true}}
             {:id "community-prod"
              :source-paths ["src"]
              :compiler {:output-to "../app/assets/javascripts/client-prod.js"
                         :optimizations :advanced
                         :pretty-print false}}]})
