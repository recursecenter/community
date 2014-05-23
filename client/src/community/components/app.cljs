(ns community.components.app
  (:require [community.api :as api]
            [community.routes :as routes]
            [community.components.shared :as shared]
            [community.util :refer-macros [<?]]
            [om.core :as om]
            [sablono.core :refer-macros [html]])
  (:require-macros [cljs.core.async.macros :refer [go]]))

(defn navbar-component [app owner]
  (reify
    om/IDisplayName
    (display-name [_] "NavBar")

    om/IRender
    (render [this]
      (html
        [:nav.navbar.navbar-default {:role "navigation"}
         [:div.container
          [:a.navbar-brand {:href "#"} "Community"]]]))))

(defn app-component [{:as app :keys [current-user route-data]}
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
          (if (not current-user)
            [:h1 "Logging in..."]
            [:div
             [:h1 (str "user: " (:first-name current-user))]
             (let [component (routes/dispatch route-data)]
               (om/build component app))])]]))))
