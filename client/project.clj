(defproject community "0.1.0-SNAPSHOT"
  :dependencies [[org.clojure/clojure "1.6.0"]
                 [org.clojure/clojurescript "0.0-2371"]
                 [org.clojure/core.async "0.1.346.0-17112a-alpha"]
                 [om "0.6.4"]
                 [sablono "0.2.17"]
                 [prismatic/om-tools "0.2.2"]
                 [com.cemerick/piggieback "0.1.3"]]

  :jvm-opts ^:replace ["-Xmx512m" "-server"]

  :plugins [[lein-cljsbuild "1.0.3"]]

  :repl-options {:nrepl-middleware [cemerick.piggieback/wrap-cljs-repl]}

  :profiles {:dev {:source-paths ["src"]}}

  :cljsbuild {:builds [{:id "dev"
                        :source-paths ["src"]
                        :compiler {:output-to "../public/client/client-dev.js"
                                   :output-dir "../public/client/client-dev"
                                   :optimizations :none
                                   :pretty-print true
                                   :source-map "../public/client/client-dev.js.map"}}
                       {:id "test"
                        :source-paths ["src" "test"]
                        :compiler {:output-to "../public/client/client-test.js"
                                   :output-dir "../public/client/client-test"
                                   :optimizations :whitespace
                                   :pretty-print true}}
                       {:id "prod"
                        :source-paths ["src"]
                        :compiler {:output-to "../app/assets/javascripts/client-prod.js"
                                   :optimizations :advanced
                                   :pretty-print false
                                   :externs ["react-externs.js" "marked-externs.js" "highlight-externs.js" "bootstrap-tooltip-externs.js"]}}]})
