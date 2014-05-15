(ns community.core
  (:require [community.api :as api]
            [community.util :as util :refer-macros [<?]]
            [community.util.routing :as r]
            [om.core :as om]
            [om.dom :as dom]
            [cljs.core.async :as async])
  (:require-macros [cljs.core.async.macros :refer [go]]))

(enable-console-print!)

;;;;;; prototype app-state
(comment

  ;; app-state
  {:current-user current-user
   :subforum-groups subforum-groups}

  ;; current-user
  {:first-name "" :last-name "" :email "" :avatar ""}

  ;; subforum-groups
  [{:name "Subforum group 1"
    :subforums subforums}
   ...]

  ;; subforums
  [{:name "Subforum 1"
    :unread? true
    :description ""
    :threads threads}
   ...]

  ;; threads
  [{:name "Thread 1"
    :author user1
    :last-updated Date
    :unread? true
    :posts posts}
   ...]

  ;; user1
  like current-user

  ;; posts
  [{:author user1
    :content "important discussion"
    :last-modified Date
    :created-at Date}
   ...]



  )

(def app-state
  (atom {:route-data nil
         :current-user nil
         :subforum-groups []}))

(def routes
  (r/routes
    (r/route :index [])
    (r/route :subforum ["f" :id])))

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
                                      (dom/li nil (link-to (routes :subforum {:id (:id subforum)})
                                                           (:name subforum))))))))))))

    om/IDidMount
    (did-mount [this]
      (go
        (om/update! app :subforum-groups (<? (api/GET "/subforum_groups")))))))


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

(js/$
 #(om/root *forum-view
           app-state
           {:target (.getElementById js/document "app")}))
