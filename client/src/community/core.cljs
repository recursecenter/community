(ns community.core
  (:require [community.api :as api]
            [community.util :as util :refer-macros [<? p]]
            [community.util.routing :as r]
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
                    :keys [current-user subforum-groups subforums]}
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
                           (when-not (empty? (:subforum-ids group))
                             (apply dom/ol nil
                                    (for [subforum (map subforums (:subforum-ids group))]
                                      (dom/li nil (link-to (routes :subforum {:id (:id subforum)
                                                                              :slug (:slug subforum)})
                                                           (:name subforum))))))))))))

    om/IDidMount
    (did-mount [this]
      (go
        (let [{:keys [subforum-groups subforums]} (<? (api/forum-index))]
          (om/update! app :subforum-groups subforum-groups)
          (om/update! app :subforums subforums))))))


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
          (let [user (<? (api/current-user))]
            (if (not= user :community.api/no-current-user)
              (om/update! app :current-user user)
              (set! (.-location js/document) "/login")))

          (catch ExceptionInfo e
            ;; TODO: display an error modal
            (prn (ex-data e))))))))

(defn init-app
  "Mounts the om application onto target element."
  [target]
  (om/root *app-view app-state {:target target}))
