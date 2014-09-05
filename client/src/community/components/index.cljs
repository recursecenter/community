(ns community.components.index
  (:require [community.state :as state]
            [community.util :as util :refer-macros [<?]]
            [community.partials :as partials :refer [link-to]]
            [community.components.shared :as shared]
            [community.components.subforum-info :refer [->subforum-info]]
            [community.routes :refer [routes]]
            [om.core :as om]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :as html :refer-macros [html]]))

(defn subforum-group [{:keys [name subforums id]}]
  (html
    [:div.subforum-group {:key id}
     [:div.subforum-group-name [:h1.title-caps name]]
     [:ul.subforums
      (for [{:keys [id] :as subforum} subforums]
        [:li {:key id} (->subforum-info subforum)])]]))

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
