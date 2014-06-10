(ns community.components.app
  (:require [community.api :as api]
            [community.routes :as routes]
            [community.components.shared :as shared]
            [community.util :refer-macros [<? p]]
            [community.partials :as partials]
            [om.core :as om]
            [sablono.core :refer-macros [html]])
  (:require-macros [cljs.core.async.macros :refer [go]]))

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
          (when (not (empty? errors))
            [:div
             (for [error errors]
               [:div.alert.alert-danger error])])
          (if current-user
            [:div
             (let [component (routes/dispatch route-data)]
               (om/build component app))])]]))))
