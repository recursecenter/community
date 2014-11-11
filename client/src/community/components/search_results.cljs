(ns community.components.search-results
  (:require [community.routes :as routes :refer [routes]]
            [community.util :as util :refer-macros [p]]
            [community.util.search :refer [search!]]
            [community.partials :as partials :refer [link-to]]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :refer-macros [html]]))

(defn result [{:keys [post author thread subforum highlight]}]
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
       (link-to (routes :subforum {:id (:id subforum)
                                   :slug (:slug subforum)})
                {:style {:color (:ui-color subforum)}}
                (:subforum-group-name subforum) " / " (:name subforum))]]
     [:div.result
      [:div.title
       (link-to (routes :thread {:id (:id thread)
                                 :slug (:slug thread)
                                 :post-number (:post-number post)})
                {:style {:color (:ui-color subforum)}}
                [:h4 (:title thread)])]
      [:div.body
       (partials/html-from-markdown highlight)]]]))

(defn load-page [query filters page]
  (search! (assoc {} :page page :text query :filters (if filters @filters nil))))

(defn pagination [{:keys [current-page total-pages query filters]}]
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
    (letfn [(page-number [class-name jump content]
              [:li {:class class-name}
               ;;TODO: Use link-to here instead (this might require
               ;;refactoring/adding behavior to link-to)
               [:a {:onClick #(load-page query filters jump)} content]])]
      (html
        (when (> total-pages 1)
          [:ul.page-links
           ;;Show - Previous, First page, Initial ellipsis
           (page-number (when (= current-page 1) "disabled")
                        (dec current-page)
                        "Previous")
           (page-number (when (= current-page 1) "active") 1 "1")
           (when first-ellipsis?
             [:li "…"])

           ;;Show rest of pages
           (for [page mid-range]
             (page-number (when (= page current-page) "active") page page))

           ;;Show - Final ellipsis, Last page, Next
           (when last-ellipsis?
             [:li "…"])
           (page-number (when (= current-page total-pages) "active") total-pages total-pages)
           (page-number (when (= current-page total-pages) "disabled")
                        (inc current-page)
                        "Next")])))))

(defcomponent search-results [{:keys [search] :as app} owner]
  (display-name [_] "Search Results")

  (render [_]
    (let [results (:results search)
          {:as metadata :keys [hits took query filters]} (:metadata search)]
      (html
        [:div {:id "search-results-view"}
         [:div.query (if (:author filters)
                       (str (util/pluralize hits "post") " by " (:author filters) ".")
                       (str (util/pluralize hits "post") " matching \"" query "\"."))]
         (when-not (empty? results)
           [:div
            [:div.results (map (partial result) results)]
            [:div.paginate (pagination metadata)]])]))))
