(ns community.api
  (:require [community.models :as models]
            [community.util :as util :refer-macros [<? p]]
            [community.util.pubsub :as pubsub]
            [cljs.core.async :as async]
            [clojure.walk :refer [postwalk]]
            [community.util.ajax :as ajax])
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

(defn csrf-token []
  ;; CSRF tokens won't be checked on GET or HEAD, but we'll
  ;; send them every time regardless to make our lives easier
  (-> (.getElementsByName js/document "csrf-token")
      (aget 0)
      (.-content)))

(defn error-message [error]
  (case (:status error)
    0 "Could not reach the server."
    "Oops! Something went wrong."))

(defn request
  "Makes an API request to the Hacker School API with some default
  options, returning a core.async channel containing either a
  response or an ExceptionInfo error."
  ([request-fn resource]
     (request request-fn resource {}))
  ([request-fn resource opts]
     (let [out (async/chan 1)
           on-error (fn [error-res]
                      (let [err (ex-info (str "Failed to access " resource)
                                         (assoc error-res :message (error-message error-res)))]
                        (async/put! out err #(async/close! out))))
           on-success (fn [data]
                        (async/put! out (format-keys data) #(async/close! out)))

           default-opts {:on-success on-success
                         :on-error on-error
                         :headers {"X-CSRF-Token" (csrf-token)}}]
       (request-fn (api-path resource)
                   (merge default-opts opts))
       out)))

(def GET (partial request ajax/GET))
(def POST (partial request ajax/POST))
(def PATCH (partial request ajax/PATCH))

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

;;; PubSub via WebSockets
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(def *pubsub* (pubsub/pubsub))
(def !ws-connection (atom nil))

(defn new-ws-connection []
  (let [query-string (str "?csrf_token="
                          (js/encodeURIComponent (csrf-token)))
        l (.-location js/window)
        protocol (if (= "https:" (.-protocol l))
                     "wss://"
                     "ws://")
        ;; e.g. wss://localhost:5001/websocket?csrf_token=asdfasdf
        url (str protocol (.-host l) "/websocket" query-string)]
    (js/WebSocket. url)))

(def ^:private !ws-send-queue (atom []))

(defn send-when-ready! [ws message]
  (if (= 0 (.-readyState ws)) ; still connecting
    (do (when (empty? @!ws-send-queue) ; handler not yet set
          (set! (.-onopen ws) #(doseq [message @!ws-send-queue]
                                 (.send ws message))))
        (swap! !ws-send-queue conj message))
    (.send ws message)))

(defn begin-publishing! [ws pubsub]
  (let [onmessage (fn [e]
                    (let [js-message (.parse js/JSON (.-data e))
                          message (format-keys (js->clj js-message))]
                      (pubsub/-publish! pubsub (:feed message) message)))]
    (set! (.-onmessage ws) onmessage)))

(def !ws-connection (atom nil))

(defn ws-connection []
  (or @!ws-connection
      (let [ws (new-ws-connection)]
        (begin-publishing! ws *pubsub*)
        (reset! !ws-connection ws))))

(defmulti feed-format :feed)

(defmethod feed-format :thread [{id :id}]
  (str "thread-" id))

(def subscriptions-enabled? (boolean (.-WebSocket js/window)))

(defn subscribe!
  "Subscribes to the Community WebSockets API, returning a
  [message-chan unsubscribe!] pair."
  ([to]
     (subscribe! *pubsub* to))
  ([pubsub to]
     (when-not subscriptions-enabled?
       (throw (ex-info "Cannot call subscribe! when subscriptions aren't enabled." {})))
     (let [feed (feed-format to)
           subscription (.stringify js/JSON #js {:type "subscribe" :feed feed})
           unsubscription (.stringify js/JSON #js {:type "unsubscribe" :feed feed})

           message-chan (async/chan)
           new-message-handler (fn [message]
                                 (async/put! message-chan message))

           unsubscribe! (fn []
                          (pubsub/-unsubscribe! pubsub feed new-message-handler)
                          (send-when-ready! (ws-connection) unsubscription)
                          (async/close! message-chan))]
       (pubsub/-subscribe! pubsub feed new-message-handler)
       (send-when-ready! (ws-connection) subscription)
       [message-chan unsubscribe!])))
