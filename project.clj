(defproject community "0.1.0-SNAPSHOT"
  :dependencies [[org.clojure/clojure "1.8.0"]
                 [org.clojure/clojurescript "1.9.521"]
                 [org.clojure/core.async "0.1.346.0-17112a-alpha"]

                 [org.omcljs/om "0.8.8"]
                 [sablono "0.3.4"]
                 [prismatic/om-tools "0.4.0"]]

  :jvm-opts ^:replace ["-Xmx512m" "-server"]

  :plugins [[lein-cljsbuild "1.1.8"]]

  :profiles {:dev {:source-paths ["app/clojurescript/src"]
                   :test-paths ["app/clojurescript/test"]
                   :resource-paths ["app/clojurescript/resources"]
                   :target-path "app/clojurescript/target/%s/"}}

  :cljsbuild {:builds [{:id "development"
                        :source-paths ["app/clojurescript/src"]
                        :compiler {:output-to "app/assets/builds/client_development.js"
                                   :output-dir "app/assets/builds/client_development"
                                   :optimizations :none
                                   :pretty-print true
                                   :closure-defines {"goog.json.USE_NATIVE_JSON" true}
                                   :source-map true}}
                       {:id "test"
                        :source-paths ["app/clojurescript/src", "app/clojurescript/test"]
                        :compiler {:output-to "app/assets/builds/client_test.js"
                                   :output-dir "app/assets/builds/client_test"
                                   :optimizations :whitespace
                                   :closure-defines {"goog.json.USE_NATIVE_JSON" true}
                                   :pretty-print true}}
                       {:id "production"
                        :source-paths ["app/clojurescript/src"]
                        :compiler {:output-to "app/assets/builds/client_production.js"
                                   :optimizations :advanced
                                   :pretty-print false
                                   :closure-defines {"goog.json.USE_NATIVE_JSON" true}
                                   :externs ["marked-externs.js" "highlight-externs.js" "bootstrap-tooltip-externs.js"]}}]})
