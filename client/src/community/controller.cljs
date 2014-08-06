(ns community.controller
  (:require [community.state :as state]
            [community.api :as api]
            [community.api.push :as push-api]
            [community.models :as models]
            [community.util :as util :refer-macros [<?]]
            [community.routes :as routes :refer [routes]]
            [cljs.core.async :as async])
  (:require-macros [cljs.core.async.macros :refer [go]]))

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

;;; State transform helpers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn append-or-update-post
  "Assumes :created-at is always increasing."
  [posts post]
  (let [created-at (:created-at post)]
    (if (or (empty? posts) (> created-at (:created-at (peek posts))))
      (conj posts post)
      (let [i (util/reverse-find-index #(= (:id %) (:id post)) posts)]
        (assoc posts i post)))))

(defn append-or-update-post! [app-state post]
  (swap! app-state update-in [:thread :posts]
    append-or-update-post (models/api->model :post post)))

(defn add-notification! [app-state notification]
  (swap! app-state update-in [:current-user :notifications]
    conj (models/api->model :notification notification)))

(defn add-error! [app-state korks e]
  (let [ks (if (vector? korks) korks [korks])]
    (swap! app-state update-in (conj ks :errors)
      conj (state/error-message (ex-data e)))))

(defn remove-errors! [app-state korks]
  (let [ks (if (vector? korks) korks [korks])]
    (swap! app-state assoc-in (conj ks :errors) #{})))

;;; Controller actions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn subscribe-to-user-notifications [app-state]
  (when push-api/subscriptions-enabled?
    (go
      (let [[notifications-feed unsubscribe!] (push-api/subscribe! {:feed :notifications :id (-> @app-state :current-user :id)})]
        (while true
          (when-let [message (<! notifications-feed)]
            (add-notification! app-state (:data message))))))))

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
      (let [data (<? (api-call))]
        (swap! app-state assoc
          key data
          :route-data route-data)
        (state/remove-errors! :ajax)
        data)

      (catch ExceptionInfo e
        (let [e-data (ex-data e)]
          (if (== 404 (:status e-data))
            (dispatch :route-changed {:route :page-not-found})
            (state/add-error! (:error-info e-data))))
        nil)

      (catch Exception e
        (.log js/console e)
        nil)

      (finally
        (swap! app-state assoc :loading? false)))))

(defmulti update-route-data (fn [app-state {route :route}] route)
  :default :page-not-found)

(defmethod update-route-data :index [app-state route-data]
  (load-from-api app-state route-data :subforum-groups api/subforum-groups))

(defmethod update-route-data :subforum [app-state route-data]
  (load-from-api app-state route-data :subforum #(api/subforum (:id route-data))))

(defn start-thread-subscription [app-state]
  (when push-api/subscriptions-enabled?
    (go
      (let [[thread-feed unsubscribe!] (push-api/subscribe! {:feed :thread :id (-> @app-state :thread :id)})]
        (swap! app-state assoc-in [:route-data :push-unsubscribe!] unsubscribe!)
        (loop []
          (when-let [message (<! thread-feed)]
            (append-or-update-post! app-state (:data message))
            (recur)))))))

(defmethod update-route-data :thread [app-state route-data]
  (go
    (when (<! (load-from-api app-state route-data :thread #(api/thread (:id route-data))))
      (start-thread-subscription app-state))))

(defmethod update-route-data :settings [app-state route-data]
  (swap! app-state assoc :route-data route-data))

(defmethod update-route-data :page-not-found [app-state route-data]
  (swap! app-state assoc :route-data {:route :page-not-found}))

(defn handle-route-changed [app-state route-data]
  (when-let [push-unsubscribe! (-> @app-state :route-data :push-unsubscribe!)]
    (push-unsubscribe!))
  (update-route-data app-state route-data))

(defn handle-new-thread [app-state new-thread]
  (go
    (try
      (swap! app-state assoc-in [:subforum :submitting?] true)
      (let [{:keys [id autocomplete-users]} (-> @app-state :subforum)
            thread (<? (api/new-thread id (models/with-mentions new-thread autocomplete-users)))]
        (routes/redirect-to (routes :thread thread)))

      (catch ExceptionInfo e
        (swap! app-state assoc-in [:subforum :submitting?] false)
        (add-error! app-state :subforum e)))))

(defn handle-new-post [app-state new-post]
  (go
    (try
      (swap! app-state assoc-in [:thread :submitting?] true)
      (let [autocomplete-users (-> @app-state :thread :autocomplete-users)
            post-with-mentions (models/with-mentions new-post autocomplete-users)
            post (<? (api/new-post post-with-mentions))]
        (append-or-update-post! app-state post)
        (swap! app-state update-in [:thread]
          (fn [thread] (assoc thread :new-post (models/empty-post (:id thread)))))
        (remove-errors! app-state :thread))

      (catch ExceptionInfo e
        (add-error! app-state :thread e))

      (finally
        (swap! app-state assoc-in [:thread :submitting?] false)))))

(defn handle-update-post [app-state post index]
  (go
    (try
      (swap! app-state assoc-in [:thread :posts index :submitting?] true)
      (let [autocomplete-users (-> @app-state :thread :autocomplete-users)
            post-with-mentions (models/with-mentions post autocomplete-users)
            updated-post (<? (api/update-post post-with-mentions))]
        (append-or-update-post! app-state updated-post)
        (remove-errors! app-state [:thread :posts index])
        (swap! app-state assoc-in [:thread :posts index :editing?] false))

      (catch ExceptionInfo e
        (add-error! app-state [:thread :posts index] e))

      (finally
        (swap! app-state assoc-in [:thread :posts index :submitting?] false)))))

;;; Main loop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defn handle
  "Handles a single controller message, possibly updating app-state."
  [app-state [tag & args]]
  (let [handler (condp keyword-identical? tag
                  :route-changed handle-route-changed
                  :new-thread handle-new-thread
                  :update-post handle-update-post
                  :new-post handle-new-post)]
    (apply handler app-state args)))

(defn start-loop! [app-state]
  (let [c (register)]
    (go
      ;; fetch the current user before handling any other actions
      (when (<! (fetch-current-user app-state))
        (while true (handle app-state (<! c)))))))
