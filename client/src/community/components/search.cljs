(ns community.components.search
  (:require [community.controller :as controller]
            [community.models :as models]
            [community.routes :as routes :refer [routes]]
            [community.components.shared :as shared]
            [community.util :as util :refer-macros [<? p]]
            [community.partials :as partials]
            [om.core :as om]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :refer-macros [html]])
  (:require-macros [cljs.core.async.macros :refer [go]]))
  
(defcomponent result [{:keys [-source] :as app} result]
  (display-name [_] "Result")
  
  (render [_]
    (html
      [:div.search-result
        [:h3.thread-title (:thread-title -source)]
        [:p.post (:body -source)]
        [:p.post.small (:author-name -source)]])))

(defcomponent search [{:keys [search] :as app} owner]
  (display-name [_] "Search Results")

  (render [_]
    (let [results (:results search)]
      (if (empty? results)
        (html
          [:div
           "Sorry, there were no matching results for this search."])
        (html
          [:div.results (map (partial ->result) results)])))))
