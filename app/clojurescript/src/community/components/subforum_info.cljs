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
     (html
       [:span.post-number-unread.label.label-info
        (link-to (routes :thread thread)
                 (if n [:span n " new"] "new"))])))

(defn post-number-read [n]
  (html [:span.post-number-read (util/pluralize n "post")]))

(defn subforum-info-header [{:keys [id slug ui-color name description] :as subforum}
                            {:keys [title-link?]}]
  (html
    [:div.subforum-info-header
     [:div.subforum-name
      (if title-link?
        (link-to (routes :subforum {:id id :slug slug})
                 {:style {:color ui-color}}
                 [:h3 name])
        [:h3 name])
      [:div.subscribers
       [:span.title-caps.small
        (let [{:keys [n-thread-subscribers n-subscribers]} subforum]
          (cond n-thread-subscribers
                (str "Thread subscribers: " n-thread-subscribers)
                n-subscribers
                (str "Subscribers: " n-subscribers)))]]
      [:p.subforum-description description]]]))

(defn threads-list [{:keys [threads ui-color n-threads] :as subforum} nowrap?]
  (html
    [:ol.threads
     [:li
      [:div.row.headers.hidden-xs
       [:div.last-updated-info.mini-col-header "Latest"]
       [:div.title.mini-col-header "Thread"]
       [:div.created-by.mini-col-header "Created by"]
       [:div.n-posts.mini-col-header]]]
     (for [{:as thread :keys [title unread]} threads]
       [:li.thread
        [:div.row
         [:div.last-updated-info.meta
          [:span.timestamp (util/human-format-time (:last-post-created-at thread))]
          [:span.user-name (:last-posted-to-by thread)]]
         [:div.title
          [:p {:class (when nowrap? "nowrap-text")}
           (when (:pinned thread)
             [:i.fa.fa-thumb-tack.pinned-icon])
           (link-to (routes :thread thread) {:style {:color ui-color}}
                    (if unread [:strong title] title))]]
         [:div.created-by.meta.hidden-xs
          [:span.user-name (get-in thread [:created-by :name])]]
         [:div.n-posts.meta.hidden-xs
          (let [{:keys [last-post-number-read highest-post-number]} thread]
            [:span (post-number-read highest-post-number)
             (cond (zero? last-post-number-read) (post-number-unread thread)
                   (< last-post-number-read highest-post-number) (post-number-unread (- highest-post-number last-post-number-read) thread))])]]])
     (when n-threads
       [:li [:div.more-threads
             (link-to (routes :subforum subforum)
                      {:style {:color ui-color}}
                      [:span [:i.fa.fa-list-ul.small] " " (util/pluralize n-threads "thread")])]])]))

(defcomponent subforum-info [{:keys [threads] :as subforum}
                             owner
                             {:keys [nowrap? title-link?] :or {nowrap? true title-link? true}}]
  (display-name [_] "SubforumInfo")

  (should-update [_ next-props next-state]
    (not= (dissoc subforum :new-thread) (dissoc next-props :new-thread)))

  (render [_]
    (html
      [:div.subforum-info
       (subforum-info-header subforum {:title-link? title-link?})
       (if (empty? threads)
         [:p.no-threads "No threads yet..."]
         [:div.subforum-threads
          [:div.subforum-top-bar {:style {:background-color (:ui-color subforum)}}]
          (threads-list subforum nowrap?)])])))
