(ns community.components.index
  (:require [community.state :as state]
            [community.util :as util :refer-macros [<?]]
            [community.partials :as partials :refer [link-to]]
            [community.components.shared :as shared]
            [community.routes :refer [routes]]
            [om.core :as om]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :as html :refer-macros [html]])
  (:require-macros [cljs.core.async.macros :refer [go]]))

(defn post-number-unread
  ([thread]
     (post-number-unread nil thread))
  ([n thread]
     [:span.post-number-unread.label.label-info
      (link-to (routes :thread thread)
               (if n [:span n " new"] "new"))]))

(defn post-number-read [n]
  [:span.post-number-read (util/pluralize n "post")])

(defn subforum-info-header [{:keys [id slug ui-color name recent-threads] :as subforum}]
  [:div.header-info
   [:div.subforum-name
    (link-to (routes :subforum {:id id :slug slug})
             {:style {:color ui-color}}
             [:h3 name])
    [:div [:span.title-caps.small "Subscribers: " (:n-subscribers subforum)]]
    [:p.subforum-description (:description subforum)]]])

(defn recent-threads-list [{:keys [recent-threads ui-color n-threads] :as subforum}]
  [:div.subforum-recent-threads
   [:div.subforum-top-bar {:style {:background-color ui-color}}]
   [:ol.recent-threads
    (for [{:as thread :keys [title unread]} recent-threads]
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

(defn subforum-info [{:keys [id slug ui-color name recent-threads] :as subforum}]
  (html
    [:li {:key id}
     (subforum-info-header subforum)
     (if (empty? recent-threads)
       [:p.no-threads "No threads yet..."]
       (recent-threads-list subforum))]))

(defn subforum-group [{:keys [name subforums id]}]
  (html
    [:div.subforum-group {:key id}
     [:div.subforum-group-name [:h1.title-caps name]]
     [:ul.subforums (map subforum-info subforums)]]))

(defcomponent index [{:keys [subforum-groups]} owner]
  (display-name [_] "Index")

  (render [this]
    (html
      [:div#subforum-index
       [:div.row
        [:ul.inline-links.quick-links
         (for [{:keys [subforums]} subforum-groups
               subforum subforums]
           [:li (link-to (routes :subforum subforum)
                         {:style {:color (:ui-color subforum)}}
                         (:name subforum))])]]
       (map subforum-group subforum-groups)])))
