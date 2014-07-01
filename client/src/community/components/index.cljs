(ns community.components.index
  (:require [community.util :refer-macros [<?]]
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
      [:table.table.table-striped
       [:thead
        [:tr [:th "Subforum"]]]
       [:tbody
        (for [{:keys [id slug] :as subforum} subforums]
          [:tr {:key id :className (if (:unread subforum) "unread")}
           [:td (link-to (routes :subforum {:id id :slug slug})
                         (:name subforum))]])]]) ]))

(defcomponent index [{:as app :keys [current-user subforum-groups]}
                     owner]
  (display-name [_] "Index")

  (did-mount [this]
    (go
      (try
        (om/update! app :subforum-groups (<? (api/subforum-groups)))
        (om/transact! app :errors #(reduce disj % (vals (:ajax api/errors))))

        (catch ExceptionInfo e
          (let [e-data (ex-data e)]
            (om/transact! app :errors #(conj % (:message e-data))))))))

  (render [this]
    (html
      (if (not (empty? subforum-groups))
        [:div
         [:ol.list-unstyled
          (map subforum-group subforum-groups)]]
        [:div]))))
