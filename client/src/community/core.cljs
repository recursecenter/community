(ns community.core
  (:require [community.api :as api]
            [community.util :as util :refer-macros [<?]]
            [community.util.routing :as r]
            [community.models :as models]
            [om.core :as om]
            [om.dom :as dom]
            [cljs.core.async :as async])
  (:require-macros [cljs.core.async.macros :refer [go]]))

(enable-console-print!)

(def app-state
  (atom {:route-data nil
         :current-user nil
         :subforum-groups []
         :subforums {}}))

(def routes
  (r/routes
    (r/route :index [])
    (r/route :subforum ["f" :slug :id])))

(def *pushstate-enabled*
  (boolean (.-pushState js/history)))

(defn link-to [route & body]
  (apply dom/a #js {:href route
                    :onClick (fn [e]
                               (when *pushstate-enabled*
                                 (.preventDefault e)
                                 (.pushState js/history nil nil route)
                                 (.dispatchEvent js/window (js/Event. "popstate"))))}
         body))

(defn set-route! [app]
  (let [route (routes (-> js/document .-location .-pathname))]
    (swap! app assoc :route-data route)))

;; set initial route
(set-route! app-state)

;; TODO:
;; - somehow render different componenets based on the route
;; - set page title
(.addEventListener js/window "popstate" (partial set-route! app-state))


;;; Views
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; Subforum groups and subforums
;;
(defn *forum-view [{:as app
                    :keys [current-user subforum-groups]}
                   owner]
  (reify

    om/IRender
    (render [this]
      (dom/div nil
        (when-not (empty? subforum-groups)
          (apply dom/ol #js {:id "subforum-groups"}
                 (for [group subforum-groups]
                   (dom/li nil
                           (dom/h2 nil (:name group))
                           (when-not (empty? (:subforums group))
                             (apply dom/ol nil
                                    (for [subforum (:subforums group)]
                                      (dom/li nil (link-to (routes :subforum {:id (:id subforum)
                                                                              :slug (:slug subforum)})
                                                           (:name subforum))))))))))))

    om/IDidMount
    (did-mount [this]
      ;; TODO: Fix?
      (go
        (let [api-data (<? (api/GET "/subforum_groups"))
              subforum-groups (mapv models/subforum-group api-data)
              subforum-list (mapv models/subforum (mapcat :subforums api-data))
              subforums (into {} (map vector (map :id subforum-list) subforum-list))]
          (om/update! app :subforum-groups subforum-groups))))))


;; Subforum view, displays threads
;;
(defn *subforum-view [{:as app
                       :keys []}
                      owner]
  (reify

    om/IRender
    (render [this]
      (dom/h1 nil "a subforum"))))


;; Main app, responsible for login
;;
(defn *app-view [{:as app
                  :keys [current-user route-data]}
                 owner]
  (reify

    om/IRender
    (render [this]
      (dom/div #js{:id "app"}
        (if-not current-user
          (dom/h1 nil "Logging in...")
          (dom/div nil
            (dom/h1 nil (str "user: " (:first-name current-user)))
            ;; view dispatch
            (case (:route route-data)
              :index (om/build *forum-view app)
              :subforum (om/build *subforum-view app))))))

    om/IDidMount
    (did-mount [this]
      (go
        (try
          (om/update! app :current-user (<? (api/GET "/users/me")))

          (catch ExceptionInfo e
            (if (== 403 (:status (ex-data e)))
              (set! (.-location js/document) "/login")
              ;; TODO: display an error modal
              (prn (ex-data e)))))))))

(defn init-app
  "Mounts the om application onto target element."
  [target]
  (om/root *app-view app-state {:target target}))
