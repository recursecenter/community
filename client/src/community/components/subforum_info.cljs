(ns community.components.subforum-info
  (:require [community.util :as util :refer-macros [<?]]
            [community.partials :as partials :refer [link-to]]
            [community.routes :refer [routes]]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :as html :refer-macros [html]]))

(defn post-number-unread
  ([thread]
     (post-number-unread nil thread))
  ([n thread]
     [:span.post-number-unread.label.label-info
      (link-to (routes :thread thread)
               (if n [:span n " new"] "new"))]))

(defn post-number-read [n]
  [:span.post-number-read (util/pluralize n "post")])

(defn subforum-info-header [{:keys [id slug ui-color name threads] :as subforum}]
  [:div.header-info
   [:div.subforum-name
    (link-to (routes :subforum {:id id :slug slug})
             {:style {:color ui-color}}
             [:h3 name])
    [:div [:span.title-caps.small "Subscribers: " (:n-subscribers subforum)]]
    [:p.subforum-description (:description subforum)]]])

(defn threads-list [{:keys [threads ui-color n-threads] :as subforum}]
  [:div.subforum-threads
   [:div.subforum-top-bar {:style {:background-color ui-color}}]
   [:ol.threads
    (for [{:as thread :keys [title unread]} threads]
      [:li
       [:div.row
        [:div.last-updated-info.meta
         [:span.timestamp (util/human-format-time (:updated-at thread))]
         [:span.user-name (:last-posted-to-by thread)]]
        [:p.title (link-to (routes :thread thread) {:style {:color ui-color}}
                           (if unread [:strong title] title))]
        [:div.post-number-info.meta.hidden-xs
         (let [{:keys [last-post-number-read highest-post-number]} thread]
           [:span (post-number-read highest-post-number)
            (cond (zero? last-post-number-read) (post-number-unread thread)
                  (< last-post-number-read highest-post-number) (post-number-unread (- highest-post-number last-post-number-read) thread))])]
        [:div.n-thread-subscribers.meta.hidden-xs
         (util/pluralize (:n-subscribers thread) "subscriber")]]])
    [:li [:div.more-threads
          (link-to (routes :subforum subforum)
                   {:style {:color ui-color}}
                   [:span [:i.fa.fa-list-ul.small] " " (util/pluralize n-threads "thread")])]]]])

(defcomponent subforum-info [{:keys [threads] :as subforum}]
  (display-name [_] "SubforumInfo")

  (render [_]
    (html
      [:div.subforum-info
       (subforum-info-header subforum)
       (if (empty? threads)
         [:p.no-threads "No threads yet..."]
         (threads-list subforum))])))
