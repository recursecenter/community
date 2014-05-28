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

(defn make-api-fn
  [req-fn & {:keys [res-transform err-transform]}]
  (fn [& args]
    (let [out (async/chan 1)]
      (go
        (try
          (let [res (<? (apply req-fn args))]
            (>! out ((or res-transform identity) res))
            (async/close! out))
          (catch ExceptionInfo e
            (>! out ((or err-transform identity) e)))))
      out)))

(def current-user
  (make-api-fn #(GET "/users/me")
    :res-transform models/user
    :err-transform #(if (== 403 (:status (ex-data %)))
                      ::no-current-user
                      %)))

(def subforum-groups
  (make-api-fn #(GET "/subforum_groups")
    :res-transform #(mapv models/subforum-group %)))

(def subforum
  (make-api-fn (fn [id] (GET (str "/subforums/" id)))
    :res-transform models/subforum))

(def thread
  (make-api-fn (fn [id] (GET (str "/threads/" id)))
    :res-transform models/thread))

(def new-post
  (make-api-fn (fn [post]
                 (POST (str "/threads/" (:thread-id post) "/posts")
                       {:params (dissoc post :thread-id) :format :json}))
    :res-transform models/post))

(def update-post
  (make-api-fn (fn [post]
                 (PATCH (str "/posts/" (:id post))
                        {:params {:post (dissoc post :id)} :format :json}))
    :res-transform models/post))

(def new-thread
  (make-api-fn (fn [subforum-id {:keys [title body]}]
                 (POST (str "/subforums/" subforum-id "/threads")
                       {:params {:thread {:title title} :post {:body body}}
                        :format :json}))
    :res-transform models/thread))
