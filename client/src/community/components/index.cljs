(ns community.components.index
  (:require [community.state :as state]
            [community.controller :as controller]
            [community.util :as util :refer-macros [<?]]
            [community.partials :as partials :refer [link-to]]
            [community.components.shared :as shared]
            [community.components.subforum-info :refer [->subforum-info]]
            [community.routes :refer [routes]]
            [om.core :as om]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :as html :refer-macros [html]]))

(defcomponent welcome-message [current-user owner]
  (display-name [_] "WelcomeMessage")

  (render [_]
    (html
      [:div.welcome
       [:button.close {:onClick #(controller/dispatch :welcome-message-read)} "×"]
       [:div.welcome-content
        {:dangerouslySetInnerHTML {:__html (:welcome-message current-user)}}]])))

(defn subforum-group [{:keys [name subforums id]}]
  (html
    [:div.subforum-group {:key id}
     [:div.subforum-group-name [:h1.title-caps name]]
     [:ul.subforums
      (for [{:keys [id] :as subforum} subforums]
        [:li {:key id} [:div.row.no-side-margin (->subforum-info subforum)]])]]))

(defcomponent index [{:keys [subforum-groups current-user]} owner]
  (display-name [_] "Index")

  (render [_]
    (html
      [:div#subforum-index
       [:div.row.no-side-margin
        [:ul.inline-links.quick-links
         (for [{:keys [subforums]} subforum-groups
               subforum subforums]
           [:li (link-to (routes :subforum subforum)
                         {:style {:color (:ui-color subforum)}}
                         (:name subforum))])]]
       [:div.row.no-side-margin
        (when (:welcome-message current-user)
          (->welcome-message current-user))]
       (map subforum-group subforum-groups)])))
