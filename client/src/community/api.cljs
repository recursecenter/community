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

(defn request
  "Makes an API request to the Hacker School API with some default
  options, returning a core.async channel containing either a
  response or an ExceptionInfo error."
  ([request-fn resource]
     (request request-fn resource {}))
  ([request-fn resource opts]
     (let [out (async/chan 1)

           ;; CSRF tokens won't be checked on GET or HEAD, but we'll
           ;; send them every time regardless to make our lives easier
           csrf-token (-> (.getElementsByName js/document "csrf-token")
                          (aget 0)
                          (.-content))

           ;; default handlers
           on-error (fn [error-res]
                      (let [err (ex-info (str "Failed to access " resource) error-res)]
                        (async/put! out err #(async/close! out))))
           on-possible-success (fn [res]
                                 (if (symbol? res) ; we expect edn
                                   (on-error res)
                                   (async/put! out (format-keys res) #(async/close! out))))

           default-opts {:handler on-possible-success
                         :error-handler on-error
                         :headers {"X-CSRF-Token" csrf-token}}]
       (request-fn (api-path resource)
                   (merge default-opts opts))
       out)))

(def GET (partial request ajax/GET))
(def POST (partial request ajax/POST))
(def PATCH (partial request (fn [uri opts]
                              (ajax/ajax-request uri "PATCH" (ajax/transform-opts opts)))))

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

(defn subforum-groups []
  (let [out (async/chan 1)]
    (go
      (let [res (<? (GET "/subforum_groups"))]
        (>! out
          (mapv models/subforum-group res))
        (async/close! out)))
    out))

(defn subforum [id]
  (let [out (async/chan 1)]
    (go
      (try
        (let [res (<? (GET (str "/subforums/" id)))]
          (>! out (models/subforum res)))
        (catch ExceptionInfo e
          (>! out e)))
      (async/close! out))
    out))

(defn thread [id]
  (let [out (async/chan 1)]
    (go
      (try
        (let [res (<? (GET (str "/threads/" id)))]
          (>! out (models/thread res)))
        (catch ExceptionInfo e
          (>! out e)))
      (async/close! out))
    out))

(defn new-post [post]
  (let [out (async/chan 1)]
    (go
      (try
        (let [res (<? (POST (str "/threads/" (:thread-id post) "/posts")
                            {:params (dissoc post :thread-id) :format :json}))]
          (>! out (models/post res)))
        (catch ExceptionInfo e
          (>! out e)))
      (async/close! out))
    out))

(defn update-post [post]
  (let [out (async/chan 1)]
    (go
      (try
        (let [res (<? (PATCH (str "/posts/" (:id post))
                             {:params {:post (dissoc post :id)} :format :json}))]
          (>! out (models/post res)))
        (catch ExceptionInfo e
          (>! out e)))
      (async/close! out))
    out))

(defn new-thread [subforum-id {:keys [title body]}]
  (let [out (async/chan 1)]
    (go
      (try
        (let [res (<? (POST (str "/subforums/" subforum-id "/threads")
                            {:params {:thread {:title title} :post {:body body}}
                             :format :json}))]
          (>! out (models/thread res)))
        (catch ExceptionInfo e
          (>! out e)))
      (async/close! out))
    out))
