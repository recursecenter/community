(ns community.util.pubsub
  (:require [cljs.core.async :as async]))

(defprotocol ISubscribe
  (-subscribe! [this feed handler])
  (-unsubscribe! [this feed handler]))

(defprotocol IPublish
  (-publish! [this feed message]))

(defrecord PubSub [!subscriptions] ;; (atom {feed #{handler ...}, ...})
  ISubscribe
  (-subscribe! [_ feed handler]
    (swap! !subscriptions update-in [feed] (fnil conj #{}) handler))
  (-unsubscribe! [_ feed handler]
    (swap! !subscriptions update-in [feed] dissoc handler))

  IPublish
  (-publish! [_ feed message]
    (doseq [handler (get @!subscriptions feed)]
      (handler message))))

(defn pubsub []
  (->PubSub (atom {})))
