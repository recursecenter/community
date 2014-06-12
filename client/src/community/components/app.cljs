(ns community.components.app
  (:require [community.api :as api]
            [community.routes :as routes]
            [community.components.shared :as shared]
            [community.util :refer-macros [<? p]]
            [community.partials :as partials]
            [om.core :as om]
            [sablono.core :refer-macros [html]])
  (:require-macros [cljs.core.async.macros :refer [go]]))

(defmulti notification-summary :type)

(defmethod notification-summary "mention" [mention]
  (html
    [:div
     [:strong (-> mention :mentioned-by :name)]
     " mentioned you in "
     [:strong (-> mention :thread :title)]]))

(defn notifications-component [app owner]
  (reify
    om/IDisplayName
    (display-name [_] "Notifications")

    om/IRender
    (render [this]
      (let [notifications (-> app :current-user :notifications)]
        (html
          [:div#notifications
           [:h3 "Notifications"]
           (if (empty? notifications)
             [:div "No new notifications"]
             [:div.list-group
              (for [n notifications]
                (partials/link-to (routes/routes :thread (:thread n))
                                  {:class "list-group-item"}
                                  (notification-summary n)))])])))))

(defn navbar-component [{:keys [current-user]} owner]
  (reify
    om/IDisplayName
    (display-name [_] "NavBar")

    om/IRender
    (render [this]
      (html
        [:nav.navbar.navbar-default {:role "navigation"}
         [:div.container
          [:div.navbar-header
           (partials/link-to "/" {:class "navbar-brand"} "Community")]
          [:ul.nav.navbar-nav.navbar-right
           [:li [:a {:href "https://github.com/hackerschool/community"} "Source"]]
           (when current-user
             [:li.dropdown
              [:a.dropdown-toggle {:href "#" :data-toggle "dropdown"}
               (:name current-user) [:b.caret]]
              [:ul.dropdown-menu
               [:li [:a {:href "/logout"} "Logout"]]]])]]]))))

(defn welcome-info-component [_ owner]
  (reify
    om/IDisplayName
    (welcome-info [this] "WelcomeInfo")

    om/IInitState
    (init-state [this]
      {:closed? false})

    om/IRenderState
    (render-state [this {:keys [closed?]}]
      (html
       (if closed?
         [:div]
         [:div.row
          [:div.col-lg-12
           [:div.alert.alert-info
            [:strong "Welcome! "]
            "As you can tell, Community is in very early stages. Expect things to change, threads and posts to be deleted, etc. Thanks for checking it out!"
            [:button.close {:onClick #(om/set-state! owner :closed? true)}
             "×"]]]])))))


(defn app-component [{:as app :keys [current-user route-data errors]}
                     owner]
  (reify
    om/IDisplayName
    (display-name [_] "App")

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
      (html
        [:div
         (om/build navbar-component app)
         [:div.container
          (om/build welcome-info-component nil)
          (when (not (empty? errors))
            [:div
             (for [error errors]
               [:div.alert.alert-danger error])])
          (if current-user
            [:div.row
             [:div#main-content
              (let [component (routes/dispatch route-data)]
                (om/build component app))]
             [:div#sidebar
              (om/build notifications-component app)]])]]))))
