(ns community.controller
  (:require [community.state :as state]
            [community.api :as api]
            [community.api.push :as push-api]
            [community.models :as models]
            [community.util :refer-macros [<?]]
            [community.routes :as routes :refer [routes]]
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

;;; Controller actions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn subscribe-to-user-notifications [app-state]
  (when push-api/subscriptions-enabled?
    (go
      (let [[notifications-feed unsubscribe!] (push-api/subscribe! {:feed :notifications :id (-> @app-state :current-user :id)})]
        (while true
          (when-let [message (<! notifications-feed)]
            (swap! app-state update-in [:current-user :notifications]
              conj (models/api->model :notification (:data message)))))))))

(defn fetch-current-user [app-state]
  (go
    (try
      (swap! app-state assoc :loading? true)
      (swap! app-state assoc
        :current-user (<? (api/current-user))
        :loading? false)
      (subscribe-to-user-notifications app-state)
      true

      (catch ExceptionInfo e
        (let [e-data (ex-data e)]
          (if (= 403 (:status e-data))
            (set! (.-location js/document) "/login")
            (state/add-error! (:error-info e-data))))
        false))))

(defn load-from-api [app-state route-data key api-call]
  (go
    (try
      (swap! app-state assoc :loading? true)
      (swap! app-state assoc
        key (<? (api-call))
        :route-data route-data)
      (state/remove-errors! :ajax)

      (catch ExceptionInfo e
        (let [e-data (ex-data e)]
          (if (== 404 (:status e-data))
            (dispatch :route-changed {:route :page-not-found})
            (state/add-error! (:error-info e-data)))))

      (catch Exception e
        (.log js/console e))

      (finally
        (swap! app-state assoc :loading? false)))))

(defn handle-route-changed [app-state route-data]
  (condp keyword-identical? (:route route-data)
    :index    (load-from-api app-state route-data :subforum-groups api/subforum-groups)
    :subforum (load-from-api app-state route-data :subforum      #(api/subforum (:id route-data)))
    :thread   (load-from-api app-state route-data :thread        #(api/thread (:id route-data)))
    :settings (swap! app-state assoc :route-data route-data)
    (swap! app-state assoc :route-data {:route :page-not-found})))

(defn handle-new-thread [app-state new-thread]
  (go
    (try
      (swap! app-state assoc-in [:subforum :submitting?] true)
      (let [{:keys [id autocomplete-users]} (-> @app-state :subforum)
            thread (<? (api/new-thread id (models/with-mentions new-thread autocomplete-users)))]
        (routes/redirect-to (routes :thread thread)))

      (catch ExceptionInfo e
        (swap! app-state assoc-in [:subforum :submitting?] false)
        (swap! app-state update-in [:subforum :errors]
          conj (state/error-message (ex-data e)))))))

;;; Main loop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn handle
  "Handles a single controller message, possibly updating app-state."
  [app-state message]
  (match message
    [:route-changed route-data] (handle-route-changed app-state route-data)

    [:new-thread new-thread] (handle-new-thread app-state new-thread)))

(defn start-loop! [app-state]
  (let [c (register)]
    (go
      ;; fetch the current user before handling any other actions
      (when (<! (fetch-current-user app-state))
        (while true (handle app-state (<! c)))))))
