(ns community.components.index
  (:require [community.state :as state]
            [community.util :refer-macros [<?]]
            [community.api :as api]
            [community.partials :refer [link-to]]
            [community.routes :refer [routes]]
            [om.core :as om]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :as html :refer-macros [html]])
  (:require-macros [cljs.core.async.macros :refer [go]]))

(defn subforum-group [{:keys [name subforums id]}]
  (html
   [:li {:key id}
    [:h2 name]
    (if (not (empty? subforums))
      [:div.row
       [:div.block-grid
        (for [{:keys [id slug] :as subforum} subforums]
          [:ul
          [:li {:key id :className (if (:unread subforum) "unread")}
           [:a (link-to (routes :subforum {:id id :slug slug})
                         (:name subforum))]]])]]) ]))

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
        [:div
         [:ol.list-unstyled
          (map subforum-group subforum-groups)]]
        [:div]))))
