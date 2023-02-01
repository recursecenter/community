(defproject community "0.1.0-SNAPSHOT"
  :dependencies [[org.clojure/clojure "1.8.0"]
                 [org.clojure/clojurescript "1.9.521"]
                 [org.clojure/core.async "0.1.346.0-17112a-alpha"]

                 [org.omcljs/om "0.8.8"]
                 [sablono "0.3.4"]
                 [prismatic/om-tools "0.4.0"]]

  :jvm-opts ^:replace ["-Xmx512m" "-server"]

  :plugins [[lein-cljsbuild "1.1.8"]]

  :hooks [leiningen.cljsbuild]

  :profiles {:dev {:source-paths ["app/clojurescript/src"]
                   :test-paths ["test/clojurescript"]
                   :resource-paths ["app/clojurescript/resources"]
                   :target-path "tmp/cache/clojurescript/target/%s/"}}

  :cljsbuild {:builds [{:id "development"
                        :source-paths ["app/clojurescript/src"]
                        :compiler {:output-to "app/assets/builds/cljs_development.js"
                                   :output-dir "app/assets/builds/cljs_development"
                                   :optimizations :none
                                   :pretty-print true
                                   :closure-defines {"goog.json.USE_NATIVE_JSON" true}
                                   :main community.core
                                   :asset-path "/assets/cljs_development"
                                   :source-map true}}
                       {:id "test"
                        :source-paths ["app/clojurescript/src", "test/clojurescript"]
                        :compiler {:output-to "test/assets/builds/cljs_test.js"
                                   :output-dir "test/assets/builds/cljs_test"
                                   :optimizations :whitespace
                                   :closure-defines {"goog.json.USE_NATIVE_JSON" true}
                                   :pretty-print true}}
                       {:id "production"
                        :source-paths ["app/clojurescript/src"]
                        :compiler {:output-to "app/assets/builds/cljs_production.js"
                                   :optimizations :advanced
                                   :pretty-print false
                                   :closure-defines {"goog.json.USE_NATIVE_JSON" true}
                                   :externs ["marked-externs.js" "highlight-externs.js" "bootstrap-tooltip-externs.js"]}}]})
