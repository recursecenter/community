(ns community.api
  (:require [community.state :as state]
            [community.models :as models]
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

(def ^:private re-global-dash
  (js/RegExp. "-" "g"))

(defn string-with-underscore->keyword-with-dash
  "'foo_bar' => :foo-bar"
  [s]
  (keyword (.replace s re-global-underscore "-")))

(defn keyword-with-dash->string-with-underscore
  ":foo-bar => 'foo_bar'"
  [kw]
  (.replace (name kw) re-global-dash "_"))

(defn format-keys
  [m format-key]
  (let [f (fn [[k v]] [(format-key k) v])]
    (postwalk (fn [x]
                (if (map? x)
                  (into {} (map f x))
                  x))
              m)))

(defn csrf-token []
  ;; CSRF tokens won't be checked on GET or HEAD, but we'll
  ;; send them every time regardless to make our lives easier
  (-> (.getElementsByName js/document "csrf-token")
      (aget 0)
      (.-content)))

(defn error-info [error]
  (case (:status error)
    0 [:ajax :cant-reach-server]
    [:ajax :generic]))

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
                                         (assoc error-res :error-info (error-info error-res)))]
                        (async/put! out err #(async/close! out))))
           on-success (fn [data]
                        (async/put! out (format-keys data string-with-underscore->keyword-with-dash) #(async/close! out)))

           default-opts {:on-success on-success
                         :on-error on-error
                         :headers {"X-CSRF-Token" (csrf-token)}}
           formatted-opts (update-in opts [:params] format-keys keyword-with-dash->string-with-underscore)]
       (request-fn (api-path resource)
                   (merge default-opts formatted-opts))
       out)))

(def GET (partial request ajax/GET))
(def POST (partial request ajax/POST))
(def PATCH (partial request ajax/PATCH))

(defn make-api-fn
  "`res-transform` transforms the response if the request is successful.
  `err-transform` transforms the error-res if the request is
  unsuccessful. `validate` validates the args passed to the api-fn,
  returning an error message if there is an error, or nil if there is
  not."
  [req-fn & {:keys [res-transform err-transform validate]
             :or {res-transform identity
                  err-transform identity
                  validate (constantly nil)}}]
  (fn [& args]
    (let [out (async/chan 1)
          error-message (apply validate args)]
      (if (nil? error-message)
        (go
          (try
            (let [res (<? (apply req-fn args))]
              (>! out (res-transform res)))
            (catch ExceptionInfo e
              (>! out (err-transform e)))))
        (async/put! out (ex-info error-message {:message error-message})))
      out)))

(def current-user
  (make-api-fn #(GET "/users/me")
    :res-transform (partial models/api->model :user)
    :err-transform #(if (== 403 (:status (ex-data %)))
                      ::no-current-user
                      %)))

(def update-settings
  (make-api-fn (fn [settings-to-update]
                 (PATCH "/settings"
                        {:params {:settings settings-to-update}
                         :format :json}))))

(def subforum-groups
  (make-api-fn #(GET "/subforum_groups")
    :res-transform #(mapv (partial models/api->model :subforum-group) %)))

(def subforum
  (make-api-fn (fn [id] (GET (str "/subforums/" id)))
    :res-transform (partial models/api->model :subforum)))

(def thread
  (make-api-fn (fn [id] (GET (str "/threads/" id)))
    :res-transform (partial models/api->model :thread)))

(defn validate-post [post]
  (when (empty? (:body post))
    "The body of a post cannot be empty."))

(defn post->api-data [post]
  (let [mentions (map :id (:mentions post))]
    {:post {:body (:body post)
            :announce-to (:announce-to post)}
     :mentions (if (empty? mentions) nil mentions)}))

(def new-post
  (make-api-fn (fn [post]
                 (POST (str "/threads/" (:thread-id post) "/posts")
                       {:params (post->api-data (dissoc post :thread-id)) :format :json}))
    :res-transform (partial models/api->model :post)
    :validate validate-post))

(def update-post
  (make-api-fn (fn [post]
                 (PATCH (str "/posts/" (:id post))
                        {:params (post->api-data (dissoc post :id)) :format :json}))
    :res-transform (partial models/api->model :post)
    :validate validate-post))

(defn validate-thread [_ {:keys [title body]}]
  (cond (and (empty? title) (empty? body))
        "A new thread must have a non-empty title and body."

        (empty? title)
        "A new thread must have a non-empty title."

        (empty? body)
        "A new thread must have a non-empty body."))

(defn thread->api-data [{:keys [title body mentions]}]
  (let [mention-ids (map :id mentions)]
    {:thread {:title title}
     :post {:body body}
     :mentions (if (empty? mention-ids) nil mention-ids)}))

(def new-thread
  (make-api-fn (fn [subforum-id thread]
                 (POST (str "/subforums/" subforum-id "/threads")
                       {:params (thread->api-data thread)
                        :format :json}))
    :res-transform (partial models/api->model :thread)
    :validate validate-thread))

(def mark-notification-as-read
  (make-api-fn (fn [{id :id}]
                 (POST (str "/notifications/" id "/read")))))

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
    (when (= 1 (.-readyState ws)) ; open
      (.send ws message))))

(defn begin-publishing! [ws pubsub]
  (let [onmessage (fn [e]
                    (let [js-message (.parse js/JSON (.-data e))
                          message (format-keys (js->clj js-message) string-with-underscore->keyword-with-dash)]
                      (pubsub/-publish! pubsub (:feed message) message)))]
    (set! (.-onmessage ws) onmessage)))

(def !ws-connection (atom nil))

(defn init-ws-connection!
  "error-state should be an atom with an :errors key. An error will be
  added if the WebSocket connection closes or errors."
  [error-state]
  (let [ws (new-ws-connection)]
    (reset! !ws-connection ws)
    (begin-publishing! ws *pubsub*)
    (set! (.-onclose ws) #(state/add-error! [:websocket :closed]))
    (set! (.-onerror ws) #(state/add-error! [:websocket :errored])))
  nil)

(defmulti feed-format :feed)

(defmethod feed-format :thread [{id :id}]
  (str "thread-" id))

(defmethod feed-format :notifications [{id :id}]
  (str "notifications-" id))

(def subscriptions-enabled? (boolean (aget js/window "WebSocket")))

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
                          (send-when-ready! @!ws-connection unsubscription)
                          (async/close! message-chan))]
       (pubsub/-subscribe! pubsub feed new-message-handler)
       (send-when-ready! @!ws-connection subscription)
       [message-chan unsubscribe!])))
