(defproject community "0.1.0-SNAPSHOT"
  :dependencies [[org.clojure/clojure "1.5.1"]
                 [org.clojure/clojurescript "0.0-2234"]
                 [org.clojure/core.async "0.1.303.0-886421-alpha"]
                 [om "0.6.4"]
                 [sablono "0.2.17"]
                 [prismatic/om-tools "0.2.2"]
                 [com.cemerick/piggieback "0.1.3"]
                 [weasel "0.2.0"]]

  :plugins [[lein-cljsbuild "1.0.3"]]

  :repl-options {:nrepl-middleware [cemerick.piggieback/wrap-cljs-repl]}

  :injections [(require 'cemerick.piggieback 'weasel.repl.websocket)
               (defn browser-repl []
                 (cemerick.piggieback/cljs-repl
                  :repl-env (weasel.repl.websocket/repl-env :port 9001)))]

  :cljsbuild {:builds [{:id "test"
                        :source-paths ["src" "test"]
                        :compiler {:output-to "../public/client/client-test.js"
                                   :output-dir "../public/client/client-test"
                                   :optimizations :whitespace
                                   :pretty-print true}}
                       {:id "dev"
                        :source-paths ["src" "dev"]
                        :compiler {:output-to "../public/client/client-dev.js"
                                   :output-dir "../public/client/client-dev"
                                   :optimizations :none
                                   :pretty-print true
                                   :source-map "../public/client/client-dev.js.map"}}
                       {:id "prod"
                        :source-paths ["src"]
                        :compiler {:output-to "../app/assets/javascripts/client-prod.js"
                                   :optimizations :advanced
                                   :pretty-print false
                                   :externs ["react-externs.js" "marked-externs.js" "highlight-externs.js" "bootstrap-tooltip-externs.js"]}}]})
