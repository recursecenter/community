(ns community.components.index
  (:require [community.util :refer-macros [<?]]
            [community.api :as api]
            [community.partials :refer [link-to]]
            [community.routes :refer [routes]]
            [om.core :as om]
            [sablono.core :as html :refer-macros [html]])
  (:require-macros [cljs.core.async.macros :refer [go]]))

(defn subforum-group [{:keys [name subforums id]}]
  (html
   [:li {:key (str "subforum-group-" id)}
    [:h2 name]
    (if (not (empty? subforums))
      [:ol
       (for [{:keys [id slug] :as subforum} subforums]
         [:li {:key (str "subforum-" id)}
          (link-to (routes :subforum {:id id :slug slug})
                   (:name subforum))])])]))

(defn index-component [{:as app :keys [current-user subforum-groups]}
                       owner]
  (reify
    om/IDisplayName
    (display-name [_] "Index")

    om/IDidMount
    (did-mount [this]
      (go
        (om/update! app :subforum-groups (<? (api/subforum-groups)))))

    om/IRender
    (render [this]
      (html
       [:div
        (when (not (empty? subforum-groups))
          [:ol {:id "subforum-groups"}
           (map subforum-group subforum-groups)])]))))
