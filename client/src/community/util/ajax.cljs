(ns community.util.ajax
  (:require goog.net.XhrIo
            goog.net.EventType
            goog.events))

(defn error-response [e]
  {:status (.getStatus (.-target e))})

(defn request [url {:keys [method on-success on-error headers params]
                    :or {method "GET"
                         on-success identity
                         on-error identity
                         headers {}}}]
  (let [xhr (goog.net.XhrIo.)
        stringified-params (if params
                             (.stringify js/JSON (clj->js params))
                             nil)
        default-headers {"Content-Type" "application/json"}]
    (goog.events/listen xhr
                        goog.net.EventType/SUCCESS
                        (fn [e] (on-success (js->clj (.getResponseJson (.-target e))))))

    (goog.events/listen xhr
                        goog.net.EventType/ERROR
                        (fn [e] (on-error (error-response e))))
    (.send xhr url method stringified-params (clj->js (merge headers default-headers)))))

(defn GET [url opts] (request url (assoc opts :method "GET")))
(defn POST [url opts] (request url (assoc opts :method "POST")))
(defn PATCH [url opts] (request url (assoc opts :method "PATCH")))
