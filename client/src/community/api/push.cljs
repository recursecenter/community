(ns community.api.push
  (:require [community.util.pubsub :as pubsub]
            [community.state :as state]
            [community.api :as api]
            [cljs.core.async :as async]))

(def *pubsub* (pubsub/pubsub))
(def !ws-connection (atom nil))

(defn new-ws-connection []
  (let [query-string (str "?csrf_token="
                          (js/encodeURIComponent (api/csrf-token)))
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
                          message (api/format-keys (js->clj js-message) api/string-with-underscore->keyword-with-dash)]
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
