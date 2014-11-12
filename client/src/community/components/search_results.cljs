(ns community.components.search-results
  (:require [community.routes :as routes :refer [routes]]
            [community.util :as util :refer-macros [p]]
            [community.util.search :as search-util]
            [community.partials :as partials :refer [link-to]]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :refer-macros [html]]))


(defcomponent result [{:keys [post author thread subforum highlight]} owner]
  (display-name [_] "SearchResult")

  (render [_]
    (html
      [:div.row.search-result
       [:div.metadata {:data-ui-color (:ui-color subforum)}
        [:div.author
         [:a {:target "_blank"
              :href (routes/hs-route :person {:hacker-school-id (:hacker-school-id author)})}
          (:name author)]]
        [:div.timestamp
         (util/human-format-time (:created-at post))]
        [:div.subforum
         (link-to (routes :subforum subforum)
                  {:style {:color (:ui-color subforum)}}
                  (:subforum-group-name subforum) " / " (:name subforum))]]
       [:div.result
        [:div.title
         (link-to (routes :thread thread)
                  {:style {:color (:ui-color subforum)}}
                  [:h4 (:title thread)])]
        [:div.body
         (partials/html-from-markdown highlight)]]])))


(defn search-link [query page filters link-body]
  (let [query-data {:page page :text query :filters filters}]
    (link-to (search-util/search-path query-data) link-body)))


(defcomponent pagination [{:keys [current-page total-pages query filters]} owner]
  (display-name [_] "Pagination")

  (render [_]
    (let [max-inbetween 5
          max-display 7
          radius 2
          lower-bound (if (or (<= (- current-page radius) 2) (< total-pages max-display))
                        2
                        (- current-page radius))
          upper-bound (let [ub (+ lower-bound max-inbetween)]
                        (if (> ub total-pages) total-pages ub))
          first-ellipsis? (> lower-bound 2)
          last-ellipsis? (< upper-bound total-pages)
          mid-range (range lower-bound upper-bound)]
      (letfn [(page-number [page]
                (let [active? (= current-page page)]
                  (if active?
                    [:li.active [:span page]]
                    [:li (search-link query page filters page)])))

              (next-or-previous [direction enabled?]
                (let [[page text] (condp = direction
                                    :next [(inc current-page) "Next"]
                                    :previous [(dec current-page) "Previous"])]
                  [:li
                   (if enabled?
                     (search-link query page filters text)
                     text)]))]
        (html
          [:ul.page-links
           ;;Show - Previous, First page, Initial ellipsis
           (next-or-previous :previous (not= current-page 1))

           (page-number 1)
           (when first-ellipsis?
             [:li "…"])

           ;;Show rest of pages
           (for [page mid-range]
             (page-number page))

           ;;Show - Final ellipsis, Last page, Next
           (when last-ellipsis?
             [:li "…"])

           (when (> total-pages 1)
             (page-number total-pages))

           (next-or-previous :next (not= current-page total-pages))])))))


(defcomponent search-results [{:keys [search] :as app} owner]
  (display-name [_] "SearchResults")

  (render [_]
    (let [results (:results search)
          {:as metadata :keys [hits took query filters]} (:metadata search)]
      (html
        [:div#search-results-view
         [:div.query (if (:author filters)
                       (str (util/pluralize hits "post") " by " (:author filters) ".")
                       (str (util/pluralize hits "post") " matching \"" query "\"."))]
         (when-not (empty? results)
           [:div
            [:div.results (map ->result results)]
            [:div.paginate (->pagination metadata)]])]))))
