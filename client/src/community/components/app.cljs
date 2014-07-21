(ns community.components.app
  (:require [community.api :as api]
            [community.models :as models]
            [community.routes :as routes :refer [routes]]
            [community.location :as location]
            [community.components.shared :as shared]
            [community.util :as util :refer-macros [<? p]]
            [community.partials :as partials]
            [om.core :as om]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :refer-macros [html]])
  (:require-macros [cljs.core.async.macros :refer [go]]))

(defmulti notification-summary :type)

(defmethod notification-summary "mention" [mention]
  (html
    [:div {:class (if (:read mention) "text-muted")}
     [:strong (-> mention :mentioned-by :name)]
     " mentioned you in "
     [:strong (-> mention :thread :title)]]))

(defmulti notification-link-to :type)

(defmethod notification-link-to "mention" [mention]
  (routes :thread (:thread mention)))

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
    (.tooltip (js/jQuery (om/get-node owner "remove-button"))
              #js {:container "body"}))

  (render [_]
    (html
      [:a.list-group-item.notification-item
       {:href (notification-link-to notification)
        :onClick (fn [e]
                   (.preventDefault e)
                   (on-click e))}
       [:button.close.pull-right.notification-close
        {:onClick (fn [e]
                    (.preventDefault e)
                    (on-remove e)
                    false)
         :data-toggle "tooltip"
         :data-placement "top"
         :title "Remove"
         :ref "remove-button"}
        "×"]
       (notification-summary notification)])))

(defn clear-all-notifications [user]
  (let [notifications (:notifications @user)]
    (om/update! user :notifications [])
    (api/mark-notifications-as-read notifications)))

(defcomponent notifications [user owner]
  (display-name [_] "Notifications")

  (render [_]
    (let [notifications (:notifications user)
          unread-count (count (filter (complement :read) notifications))]
      (html
        [:ul#notifications.dropdown-menu
         [:div.unread-count-container
          [:span.unread-count.small (util/pluralize unread-count "unread notification")]
          [:button.btn.btn-link.btn-xs.pull-right {:onClick #(clear-all-notifications user)}
           "Clear all"]]
         [:li.list-group.notification-group
          (when (not (empty? notifications))
            (for [[i n] (map-indexed vector notifications)]
              (->notification {:notification n
                               :on-click #(do (mark-as-read! n)
                                              (location/redirect-to (notification-link-to @n)))
                               :on-remove #(do (mark-as-read! n)
                                               (delete-notification! user i))}
                              {:react-key (:id n)})))]]))))

(defn toggle! [owner attr]
  (om/set-state! owner attr (not (om/get-state owner attr))))

(defn transitioned? [owner attr from to]
  (and (= from (om/get-render-state owner attr))
       (= to (om/get-state owner attr))))

(defn child-of? [child parent]
  (cond (not (.-parentNode child))
        false

        (identical? (.-parentNode child) parent)
        true

        :else
        (recur (.-parentNode child) parent)))

(defcomponent notifications-dropdown [user owner]
  (init-state [_]
    {:open? false
     :on-click-cb (fn [e]
                    (when-not (child-of? (.-target e) (om/get-node owner))
                      (om/set-state! owner :open? false)))})

  (will-update [_ next-props next-state]
    (cond (transitioned? owner :open? false true)
          (.addEventListener js/document.body "click" (om/get-state owner :on-click-cb) false)

          (transitioned? owner :open? true false)
          (.removeEventListener js/document.body "click" (om/get-state owner :on-click-cb))))

  (render-state [_ {:keys [open?]}]
    (let [unread-count (count (filter (complement :read) (:notifications user)))]
      (html
        [:li.dropdown {:ref "dropdown" :class (if open? "open")}
         [:a.dropdown-toggle {:href "#"
                              :onClick (fn [e]
                                         (.preventDefault e)
                                         (toggle! owner :open?))}
          (if-not (zero? unread-count)
            [:span.badge.unread-count-icon unread-count])
          [:i.fa.fa-comments]]
         (->notifications user)]))))

(defcomponent navbar [{:as data :keys [current-user foos]} owner]
  (display-name [_] "NavBar")

  (render [_]
    (html
      [:nav.navbar.navbar-community {:role "navigation"
                                     :data-spy "affix"}
       [:div.container
        [:div.navbar-header
         [:button.navbar-toggle {:data-toggle "collapse"
                                 :data-target "#community-navbar-collapse"}
          [:span.fa.fa-bars.fa-2x.collapse-toggle]]
         (partials/link-to "/" {:class "navbar-brand"}
           [:span
            [:img {:src (routes :asset {:name "logo-small.png"})}]
            [:span.brand-text "Community"]])]
        [:div#community-navbar-collapse.collapse.navbar-collapse
         [:ul.nav.navbar-nav.navbar-right
          (when current-user
            (->notifications-dropdown current-user))
          (when current-user
            [:li.dropdown
             [:a.dropdown-toggle {:href "#" :data-toggle "dropdown"}
              (:name current-user) [:b.caret]]
             [:ul.dropdown-menu
              [:li (partials/link-to (routes :settings) "Settings")]
              [:li [:a {:href "/logout"} "Logout"]]]])]]]])))

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
                          #(conj % (models/api->model :notification (:data message))))
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
              (om/build component app))]])
        [:footer
         [:ul.list-inline
          [:li [:a {:href "https://github.com/hackerschool/community"} [:i.fa.fa-code-fork] " Source"]]]]]])))
