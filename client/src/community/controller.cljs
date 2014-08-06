(ns community.controller
  (:require [community.state :as state]
            [community.api :as api]
            [community.api.push :as push-api]
            [community.util :refer-macros [<?]]
            [cljs.core.async :as async])
  (:require-macros [cljs.core.async.macros :refer [go]]
                   [cljs.core.match.macros :refer [match]]))

;;; Dispatch utilities
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(let [c-dispatch (async/chan)
      c-dispatch-mult (async/mult c-dispatch)]

  (defn register []
    (let [c-tap (async/chan)]
      (async/tap c-dispatch-mult c-tap)
      c-tap))

  (defn unregister [c-tap]
    (async/untap c-dispatch-mult c-tap))

  (defn dispatch [tag & args]
    (async/put! c-dispatch (apply vector tag args))))

;;; Route controllers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn load-from-api [app-state route-data key api-call]
  (go
    (try
      (swap! app-state assoc :loading? true)
      (swap! app-state assoc
        key (<? (api-call))
        :route-data route-data
        :loading? false)
      (state/remove-errors! :ajax)

      (catch ExceptionInfo e
        (let [e-data (ex-data e)]
          (if (== 404 (:status e-data))
            (dispatch :route-changed {:route :page-not-found})
            (state/add-error! (:error-info e-data)))))

      (catch Exception e
        (.log js/console e)))))

(defn handle-route-changed [app-state route-data]
  (condp keyword-identical? (:route route-data)
    :index    (load-from-api app-state route-data :subforum-groups api/subforum-groups)
    :subforum (load-from-api app-state route-data :subforum #(api/subforum (:id route-data)))
    :thread   (load-from-api app-state route-data :thread #(api/thread (:id route-data)))
    :settings (swap! app-state assoc :route-data route-data)
    (swap! app-state assoc :route-data {:route :page-not-found})))

;;; Main loop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn handle
  "Handles a single controller message, possibly updating app-state."
  [app-state message]
  (match message
    [:route-changed route-data] (handle-route-changed app-state route-data)))

(defn start-loop! [app-state]
  (let [c (register)]
    (go (while true (handle app-state (<! c))))))
