(ns community.components.app
  (:require [community.api :as api]
            [community.models :as models]
            [community.routes :as routes]
            [community.location :as location]
            [community.components.shared :as shared]
            [community.util :refer-macros [<? p]]
            [community.partials :as partials]
            [om.core :as om]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :refer-macros [html]])
  (:require-macros [cljs.core.async.macros :refer [go]]))

(defmulti notification-summary :type)

(defmethod notification-summary "mention" [mention]
  (html
    [:div
     [:strong (-> mention :mentioned-by :name)]
     " mentioned you in "
     [:strong (-> mention :thread :title)]]))

(defmulti notification-link-to :type)

(defmethod notification-link-to "mention" [mention]
  (routes/routes :thread (:thread mention)))

(defn mark-as-read! [notification]
  (om/update! notification :read true)
  (api/mark-notification-as-read @notification))

(defn delete-notification!
  "Delete the i-th notification from the user's notifications."
  [user i]
  (let [notifications (:notifications @user)]
    (om/update! user :notifications
      (vec (concat (subvec notifications 0 i)
                   (subvec notifications (inc i) (count notifications)))))))

(defcomponent notification [{:keys [notification on-click on-remove]} owner]
  (display-name [_]
    "Notification")

  (did-mount [_]
    (.tooltip (js/jQuery (om/get-node owner "remove-button"))))

  (render [_]
    (html
      [:a.list-group-item
       {:href (notification-link-to notification)
        :onClick (fn [e]
                   (.preventDefault e)
                   (on-click e))}
       [:button.close.pull-right
        {:onClick (fn [e]
                    (.preventDefault e)
                    (on-remove e)
                    false)
         :data-toggle "tooltip"
         :data-placement "top"
         :title "Remove"
         :ref "remove-button"}
        "×"]
       [:div {:class (if (:read notification) "text-muted")}
        (notification-summary notification)]])))

(defcomponent notifications [user owner]
  (display-name [_] "Notifications")

  (render [_]
    (let [notifications (:notifications user)]
      (html
        [:div#notifications
         [:h3 "Notifications"]
         (if (empty? notifications)
           [:div "No new notifications"]
           [:div.list-group
            (for [[i n] (map-indexed vector notifications)]
              (->notification {:notification n
                               :on-click #(do (mark-as-read! n)
                                              (location/redirect-to (notification-link-to @n)))
                               :on-remove #(do (mark-as-read! n)
                                               (delete-notification! user i))}))])]))))

(defcomponent navbar [{:keys [current-user]} owner]
  (display-name [_] "NavBar")

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
             [:li [:a {:href "/logout"} "Logout"]]]])]]])))

(defcomponent welcome-info [_ owner]
  (welcome-info [this] "WelcomeInfo")

  (init-state [this]
    {:closed? false})

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
            "×"]]]]))))

(defn start-notifications-subscription! [user-id app]
  (when api/subscriptions-enabled?
    (go
      (let [[notifications-feed unsubscribe!] (api/subscribe! {:feed :notifications :id user-id})]
        (loop []
          (when-let [message (<! notifications-feed)]
            (om/transact! app [:current-user :notifications]
                          #(conj % (models/notification (:data message))))
            (recur)))))))

(defcomponent app [{:as app :keys [current-user route-data errors]}
                   owner]
  (display-name [_] "App")

  (did-mount [this]
    (go
      (try
        (let [user (<? (api/current-user))]
          (if (= user :community.api/no-current-user)
            (set! (.-location js/document) "/login")
            (do (om/update! app :current-user user)
                (start-notifications-subscription! (:id user) app))))

        (catch ExceptionInfo e
          ;; TODO: display an error modal
          (prn (ex-data e))))))

  (render [this]
    (html
      [:div
       (->navbar app)
       [:div.container
        (->welcome-info nil)
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
            (->notifications (:current-user app))]])]])))
