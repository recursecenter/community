(defproject community "0.1.0-SNAPSHOT"
  :dependencies [[org.clojure/clojure "1.7.0-beta1"]
                 [org.clojure/clojurescript "0.0-3196"]
                 [org.clojure/core.async "0.1.346.0-17112a-alpha"]

                 [org.omcljs/om "0.8.8"]
                 [sablono "0.3.4"]
                 [prismatic/om-tools "0.3.11"]]

  :jvm-opts ^:replace ["-Xmx512m" "-server"]

  :plugins [[lein-cljsbuild "1.0.5"]]

  :profiles {:dev {:source-paths ["src"]}}

  :cljsbuild {:builds [{:id "dev"
                        :source-paths ["src"]
                        :compiler {:output-to "../public/client/client-dev.js"
                                   :output-dir "../public/client/client-dev"
                                   :optimizations :none
                                   :pretty-print true
                                   :closure-defines {"goog.json.USE_NATIVE_JSON" true}
                                   :source-map "../public/client/client-dev.js.map"}}
                       {:id "test"
                        :source-paths ["src" "test"]
                        :compiler {:output-to "../public/client/client-test.js"
                                   :output-dir "../public/client/client-test"
                                   :optimizations :whitespace
                                   :closure-defines {"goog.json.USE_NATIVE_JSON" true}
                                   :pretty-print true}}
                       {:id "prod"
                        :source-paths ["src"]
                        :compiler {:output-to "../app/assets/javascripts/client-prod.js"
                                   :optimizations :advanced
                                   :pretty-print false
                                   :closure-defines {"goog.json.USE_NATIVE_JSON" true}
                                   :externs ["marked-externs.js" "highlight-externs.js"]}}]})
