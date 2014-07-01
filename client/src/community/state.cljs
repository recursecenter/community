(ns community.state)

(def app-state
  (atom

   {;; route-data will usually contain the currently matched route and
    ;; parsed params, of the form:
    ;;
    ;;   {:route :some-matched-route :param1 :val1 ...}
    ;;
    :route-data nil

    :current-user nil

    :subforum-groups []

    :subforum nil

    :thread nil

    :errors #{}}))

(def errors
  {:ajax
   {:cant-reach-server "Could not reach server."
    :generic "Oops! Something went wrong."}

   :websocket
   {:closed "The WebSocket connection to the server closed. Please refresh your browser to re-establish the connection."
    :errored "The WebSocket connection errored unexpectedly. Please refresh your browser to re-establish the connection."}})

(defn error-message [e-data]
  (or (:message e-data)
      (get-in errors (:error-info e-data))
      (get-in errors [:ajax :generic])))

(defn add-error! [[category error-name]]
  (if-let [error (get-in errors [category error-name])]
    (swap! app-state update-in [:errors] conj error)
    (throw (str "Invalid error " category " " error-name))))

(defn remove-errors! [category]
  (if-let [errors (get errors category)]
    (swap! app-state update-in [:errors] clojure.set/difference (vals errors))
    (throw (str "Invalid error category " category))))
