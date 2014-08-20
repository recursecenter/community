(ns community.components.index
  (:require [community.state :as state]
            [community.util :as util :refer-macros [<?]]
            [community.partials :as partials :refer [link-to]]
            [community.routes :refer [routes]]
            [om.core :as om]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :as html :refer-macros [html]])
  (:require-macros [cljs.core.async.macros :refer [go]]))

(defn subforum-item [{:keys [id slug ui-color name recent-threads]}]
  (html
    [:li.block-grid-item {:key id}
     [:div {:style {:border-color ui-color}}
      [:a (link-to (routes :subforum {:id id :slug slug})
                   {:style {:color ui-color}}
                   [:h3 name])]
      (if (empty? recent-threads)
        [:p.no-threads "No threads yet..."]
        [:ol
         (for [{:as thread :keys [title last-posted-to-by updated-at unread]} recent-threads]
           [:li
            [:span.timestamp (util/human-format-time updated-at)]
            [:span.name last-posted-to-by]
            [:p.title (link-to (routes :thread thread) {:style {:color ui-color}}
                               (if unread [:strong title] title))]])])]]))

(defn subforum-group [{:keys [name subforums id]}]
  (html
   [:div {:key id}
    [:h2.title-caps.subforum-group-name name]
    (if (not (empty? subforums))
      [:ul.subforum-blocks.block-grid-3 (map subforum-item subforums)])]))

(defcomponent index [{:keys [subforum-groups]} owner]
  (display-name [_] "Index")

  (render [this]
    (html
      [:div.row (map subforum-group subforum-groups)])))
