(ns community.components.search
  (:require [community.controller :as controller]
            [community.models :as models]
            [community.routes :as routes :refer [routes]]
            [community.components.shared :as shared]
            [community.util :as util :refer-macros [<? p]]
            [community.partials :as partials :refer [link-to]]
            [om.core :as om]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :refer-macros [html]])
  (:require-macros [cljs.core.async.macros :refer [go]]))
  
(defcomponent result [{:keys [-source] :as result}]
  (display-name [_] "Result")
  
  (render [_]
    (println -source)
    (html
      [:div.row.col-md-offset-1.col-md-9.search-result
       [:div.row.search-header 
        [:div.col-md-8 (link-to (routes :thread {:id (:thread -source)
                                                 :slug (:thread-slug -source)
                                                 :post-number (:post-number -source)})
                                {:style {:color (:ui-color -source)}}          
                                [:h4.thread-title (:thread-title -source)])]
        [:div.col-md-4 (link-to (routes :subforum {:id (:subforum -source) 
                                                   :slug (:subforum-slug -source)})
                                {:style {:color (:ui-color -source)}}
                                [:h5 (:subforum-group-name -source)
                                     " / "
                                     (:subforum-name -source)])]]
      [:div.search-body (:body -source)]
      [:div.row.search-footer 
       [:div.col-md-10 (:author-name -source)]
       [:div.col-md-2  (link-to (routes :thread {:id (:thread -source)
                                                 :slug (:thread-slug -source)
                                                 })
                                {:style {:color (:ui-color -source)}}          
                                "View thread ->")]]])))

(defcomponent search [{:keys [search] :as app} owner]
  (display-name [_] "Search Results")

  (render [_]
    (let [results (:results search)]
      (if (empty? results)
        (html
          [:div
           "Sorry, there were no matching results for this search."])
        (html
          [:div
            [:div.col-md-offset-1 [:h4 "Search Results"]]
            [:div.results (map (partial ->result) results)]])))))
