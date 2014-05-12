(ns community.api
  (:require [cljs.core.async :as async]
            [clojure.walk :refer [postwalk]]
            [ajax.core :as ajax]))

(def api-root "/api")

(defn api-path [path]
  (str api-root path))

(def ^:private re-global-underscore
  (js/RegExp. "_" "g"))

(defn format-key
  "'foo_bar' => :foo-bar"
  [s]
  (keyword (.replace s re-global-underscore "-")))

(defn format-keys
  "Recursively transforms all map keys from strings to formatted
  keywords using format-key."
  [m]
  (let [f (fn [[k v]]
            (if (string? k)
              [(format-key k) v]
              [k v]))]
    (postwalk (fn [x]
                (cond
                 (map? x) (into {} (map f x))
                 (vector? x) (into [] (map format-keys x))
                 :else x))
              m)))

(defn GET
  "Makes a GET to the Hacker School API with some default options,
  returning a core.async channel containing either a response or an
  ExceptionInfo error."
  ([resource]
     (GET resource {}))
  ([resource opts]
     (let [out (async/chan 1)
           default-opts {:handler
                         (fn [res]
                           (async/put! out (format-keys res) #(async/close! out)))

                         :error-handler
                         (fn [error-res]
                           (async/put! out
                                       (ex-info (str "Failure to GET " resource) error-res)
                                       #(async/close! out)))}]
       (ajax/GET (api-path resource)
                 (merge default-opts opts))
       out)))
