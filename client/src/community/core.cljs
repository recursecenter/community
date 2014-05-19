(ns community.core
  (:require [community.api :as api]
            [community.util :as util :refer-macros [<? p]]
            [community.util.routing :as r]
            [om.core :as om]
            [om.dom :as dom]
            [cljs.core.async :as async])
  (:require-macros [cljs.core.async.macros :refer [go]]))

(enable-console-print!)

;; TODO
(def app-state
  (atom {:route-data nil
         :current-user nil
         :subforum-groups []}))

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


;;; Components
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defn subforum-component [{:keys [route-data subforum] :as app}
                          owner]
  (reify
    om/IDidMount
    (did-mount [this]
      (go
        (try
          (let [subforum (<? (api/subforum (:id @route-data)))]
            (println subforum))

          (catch ExceptionInfo e
            ;; TODO: display an error modal
            (if (== 404 (:status (ex-data e)))
              (om/update! app [:route-data :route] :page-not-found)
              ;; TODO: generic error component
              (throw e))))))

    om/IRender
    (render [this]
      (if (and subforum (not (empty? (:threads subforum))))
        (apply dom/ol nil
               (for [thread (:threads subforum)]
                 (dom/li nil (dom/h2 nil (:topic thread)))))
        (dom/h2 nil "loading...")))))


(defn subforum-group
  [{:keys [name subforums]}]
  (dom/li nil
    (dom/h2 nil name)
    (when-not (empty? subforums)
      (apply dom/ol nil
        (for [{:keys [id slug] :as subforum} subforums]
          (dom/li nil (link-to (routes :subforum {:id id :slug slug})
                               (:name subforum))))))))

(defn forum-component [{:as app :keys [current-user subforum-groups]}
                       owner]
  (reify
    om/IDidMount
    (did-mount [this]
      (go
        (om/update! app :subforum-groups (<? (api/subforum-groups)))))

    om/IRender
    (render [this]
      (dom/div nil
        (when-not (empty? subforum-groups)
          (apply dom/ol #js {:id "subforum-groups"}
                 (map subforum-group subforum-groups)))))))

(defn page-not-found-component [app owner]
  (reify
    om/IRender
    (render [this]
      (dom/h1 nil "Page not found"))))


(defn app-component [{:as app :keys [current-user route-data]}
                     owner]
  (reify
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
            (prn (ex-data e))))))

    om/IRender
    (render [this]
      (dom/div #js{:id "app"}
        (if-not current-user
          (dom/h1 nil "Logging in...")
          (dom/div nil
            (dom/h1 nil (str "user: " (:first-name current-user)))
            ;; view dispatch
            (condp = (:route route-data)
              :index (om/build forum-component app)
              :subforum (om/build subforum-component app)
              ;; this should just be the default case
              :page-not-found (om/build page-not-found-component app))))))))

(defn init-app
  "Mounts the om application onto target element."
  [target]
  (om/root app-component app-state {:target target}))
