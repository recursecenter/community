(ns community.api
  (:require [community.models :as models]
            [community.util :as util :refer-macros [<? p]]
            [cljs.core.async :as async]
            [clojure.walk :refer [postwalk]]
            [ajax.core :as ajax])
  (:require-macros [cljs.core.async.macros :refer [go]]))

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
           on-error (fn [error-res]
                      (let [err (ex-info (str "Failure to GET " resource) error-res)]
                        (async/put! out err #(async/close! out))))
           on-possible-success (fn [res]
                                 (if (symbol? res) ; we expect edn
                                   (on-error res)
                                   (async/put! out res #(async/close! out))))
           default-opts {:handler on-possible-success
                         :error-handler on-error}]
       (ajax/GET (api-path resource)
                 (merge default-opts opts))
       out)))

(defn current-user []
  (let [out (async/chan 1)]
    (go
      (try
        (let [res (<? (GET "/users/me"))]
          (>! out (format-keys res))
          (async/close! out))
        (catch ExceptionInfo e
          (if (== 403 (:status (ex-data e)))
            (>! out ::no-current-user)
            (>! out e)))))
    out))

(defn forum-index []
  (let [out (async/chan 1)]
    (go
      (let [res (<? (GET "/pages/forum_index"))
            subforums (get res "subforums")
            subforum-groups (get res "subforum_groups")]
        (>! out
            {:subforum-groups (mapv models/subforum-group (format-keys subforum-groups))
             :subforums (into {} (for [[id subforum] subforums]
                                   [(int (name id)) (models/subforum (format-keys subforum))]))})
        (async/close! out)))
    out))
