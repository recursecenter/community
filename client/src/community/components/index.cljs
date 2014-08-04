(ns community.components.index
  (:require [community.state :as state]
            [community.util :as util :refer-macros [<?]]
            [community.api :as api]
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
                   [:h3 {:style {:color ui-color}} name])]
      (if (empty? recent-threads)
        [:p.no-threads "No threads yet..."]
        [:ol
         (for [{:as thread :keys [title last-posted-to-by marked-unread-at unread]} recent-threads]
           [:li
            [:span.timestamp (util/human-format-time marked-unread-at)]
            [:span.name last-posted-to-by]
            [:p.title (link-to (routes :thread thread) {:style {:color ui-color}}
                               (if unread [:strong title] title))]])])]]))

(defn subforum-group [{:keys [name subforums id]}]
  (html
   [:div {:key id}
    [:h2.title-caps.subforum-group-name name]
    (if (not (empty? subforums))
      [:ul.subforum-blocks.block-grid-3 (map subforum-item subforums)])]))

(defcomponent index [{:as app :keys [current-user subforum-groups]}
                     owner]
  (display-name [_] "Index")

  (did-mount [this]
    (go
      (try
        (om/update! app :subforum-groups (<? (api/subforum-groups)))
        (state/remove-errors! :ajax)

        (catch ExceptionInfo e
          (let [e-data (ex-data e)]
            (state/add-error! (:error-info e-data)))))))

  (render [this]
    (html
      (if (not (empty? subforum-groups))
        [:div.row (map subforum-group subforum-groups)]
        (partials/loading-icon)))))
