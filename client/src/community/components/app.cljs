(ns community.components.app
  (:require [community.controller :as controller]
            [community.models :as models]
            [community.routes :as routes :refer [routes]]
            [community.components.shared :as shared]
            [community.util :as util :refer-macros [<? p]]
            [community.partials :as partials]
            [community.components.search :as search]
            [om.core :as om]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :refer-macros [html]])
  (:require-macros [cljs.core.async.macros :refer [go]]))

(defmulti notification-summary :type)

(defmethod notification-summary "mention" [mention]
  (html
    [:div {:class (if (:read mention) "text-muted")}
     [:span.notification-item-name (-> mention :mentioned-by :name)]
     " mentioned you in "
     [:span.notification-item-topic (-> mention :thread :title)]]))

(defmulti notification-link-to :type)

(defmethod notification-link-to "mention" [mention]
  (routes :thread (:thread mention)))

(defn mark-as-read! [notification]
  (om/update! notification :read true)
  (controller/dispatch :notifications-read [@notification]))

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
       [:button.close.notification-close
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
    (controller/dispatch :notifications-read notifications)))

(defcomponent notifications [{:keys [user close-dropdown]} owner]
  (display-name [_] "Notifications")

  (render [_]
    (let [notifications (:notifications user)
          unread-count (count (filter (complement :read) notifications))]
      (html
        [:ul#notifications.dropdown-menu.dropdown-menu-right
         [:div.arrow-up]
         [:div.unread-count-container
          [:span.unread-count (util/pluralize unread-count "unread notification")]
          [:button.btn.btn-link.btn-xs.clear-all {:onClick #(do (clear-all-notifications user) (close-dropdown))}
           "Clear all"]]
         [:li.list-group.notification-group
          (when (not (empty? notifications))
            (for [[i n] (map-indexed vector notifications)]
              (->notification {:notification n
                               :on-click #(do (mark-as-read! n)
                                              (routes/redirect-to (notification-link-to @n))
                                              (close-dropdown))
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

(defn- make-notification-global-click-cb [owner]
  (fn [e]
    (when-not (child-of? (.-target e) (om/get-node owner))
      (om/set-state! owner :open? false))))

(defcomponent notifications-dropdown [user owner]
  (init-state [_]
    {:open? false})

  (will-update [_ next-props next-state]
    (let [old-cb (om/get-state owner :global-click-cb)]
      (cond (transitioned? owner :open? false true)
            (let [new-cb (make-notification-global-click-cb owner)]
              (when old-cb
                (.removeEventListener js/document.body "click" old-cb))
              (.addEventListener js/document.body "click" new-cb)
              (om/set-state! owner :global-click-cb new-cb))

            (transitioned? owner :open? true false)
            (.removeEventListener js/document.body "click" old-cb))))

  (render-state [_ {:keys [open?]}]
    (let [unread-count (count (filter (complement :read) (:notifications user)))]
      (html
        [:div.notifications.dropdown {:ref "dropdown" :class (if open? "open")}
         [:a.dropdown-toggle {:href "#"
                              :onClick (fn [e]
                                         (.preventDefault e)
                                         (toggle! owner :open?))}
          (if-not (zero? unread-count)
            [:span.badge.unread-count-icon unread-count])
          [:i.fa.fa-comments]]
         (->notifications {:user user :close-dropdown #(om/set-state! owner :open? false)})]))))

(defcomponent breadcrumbs [{:as app :keys [route-data ui-color]} owner]
  (display-name [_] "Breadcrumbs")

  (render [_]
    (html
      (if (contains? #{:subforum :thread} (:route route-data))
        (condp = (:route route-data)
          :subforum
          (let [subforum (:subforum app)]
            [:ol.breadcrumbs.list-inline
             [:li.active (:name subforum)]])

          :thread
          (let [thread (:thread app)]
            [:ol.breadcrumbs.list-inline
             [:li (partials/link-to (routes :subforum (:subforum thread))
                                    {:style {:color ui-color}}
                                    (:name (:subforum thread)))]
             [:li.active (:title thread)]]))
        [:div]))))


(defcomponent navbar [{:as app :keys [current-user ui-color]} owner]
  (display-name [_] "NavBar")

  (render [_]
    (html
      [:nav#navbar-community {:role "navigation" :style {:border-color ui-color}}
       [:div.navbar-header
        (partials/link-to "/"
          {:class "header-link"}
          [:span
           [:img {:src (om/get-shared owner :logo-url)}]
           [:span.brand-text {:style {:color ui-color}} "Community"]])
        [:div.breadcrumbs-container.hidden-xs (->breadcrumbs app)]
        (when current-user
          [:ul.community-nav.list-inline
           [:li.hidden-xs [:p.navbar-text "Hi, " (:first-name current-user) "!"]]
           [:li.hidden-xs (->notifications-dropdown current-user)]
           [:li (partials/link-to (routes :settings)
                  [:div [:i.fa.fa-cog] [:span.visible-xs-inline " " (:first-name current-user)]])]
           [:li.hidden-xs [:a {:href "/logout"} [:i.fa.fa-sign-out]]]])
        [:div.search-bar.hidden-xs (search/->autocomplete app)]]])))

(defcomponent app [{:as app :keys [current-user route-data errors loading?]}
                   owner]
  (display-name [_] "App")

  (render [_]
    (html
      [:div
       (->navbar app)
       [:div.container
        (when (not (empty? errors))
          [:div
           (for [error errors]
             [:div.alert.alert-danger error])])
        [:div.row
         [:div#main-content
          (cond loading?
                (partials/loading-icon)

                (and current-user route-data)
                (om/build (routes/dispatch route-data) app))]]]
       [:footer
        [:ul.inline-links
         [:li [:a {:href "https://github.com/hackerschool/community"} [:i.fa.fa-code-fork] " Source"]]
         [:li "Made with " [:i.fa.fa-heart {:style {:color "red"}}] " at " [:a {:href "https://www.hackerschool.com"} "Hacker School"]]]]])))
