(defproject community "0.1.0-SNAPSHOT"
  :dependencies [[org.clojure/clojure "1.6.0"]
                 [org.clojure/clojurescript "0.0-2371"]
                 [org.clojure/core.async "0.1.346.0-17112a-alpha"]

                 [om "0.7.3"]
                 [com.facebook/react "0.11.2"]
                 [sablono "0.2.22"]
                 [prismatic/om-tools "0.3.6"]]

  :jvm-opts ^:replace ["-Xmx512m" "-server"]

  :plugins [[lein-cljsbuild "1.0.3"]]

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
                                   :externs ["react/externs/react.js" "marked-externs.js" "highlight-externs.js" "bootstrap-tooltip-externs.js"]}}]})
