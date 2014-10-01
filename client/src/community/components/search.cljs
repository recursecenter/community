(ns community.components.search
  (:require [community.controller :as controller]
            [community.models :as models]
            [community.api :as api]
            [community.routes :as routes :refer [routes]]
            [community.components.shared :as shared]
            [community.util :as util :refer-macros [<? p]]
            [community.partials :as partials :refer [link-to]]
            [om.core :as om]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :refer-macros [html]])
  (:require-macros [cljs.core.async.macros :refer [go]]))
  
(def key->facet {:none :none :users :author :threads :thread :subforums :subforum})

(defn result->display-item
  "Given a suggestions result, convert to valid display item in the autocomplete menu"
  [key text {:keys [id slug] :or {id nil :slug nil}}]
  (let [facet (key->facet key)
        display-text (condp = facet 
                      :none
                        (str "Search for " text)
                      :author
                        (str "Narrow to posts by: " text)
                      :thread
                        (str "Narrow to thread: " text)
                      :subforum
                        (str "Narrow to subforum: " text))]
      ;{:facet facet :text display-text :id id :slug slug}
      display-text))

(defn results->display-list
  "Given all results from the suggestions endpoint, return list of things to show in the autocomplete menu"
  [q results]
  (let [always-display (result->display-item :none q nil)
        display (mapcat 
                  (fn [key result-set]
                    (when (not (empty? result-set))
                      (map
                        (fn [result] 
                          (result->display-item key (:text result) (:payload result))) result-set)))
                  (keys results) (vals results))]
    (conj display always-display)))

(defcomponent result [{:keys [-source] :as result}]
  (display-name [_] "Result")
  
  (render [_]
    (html
      [:div.row.col-md-offset-1.col-md-9.search-result
       [:div.row.header 
        [:div.col-md-8 (link-to (routes :thread {:id (:thread-id -source)
                                                 :slug (:thread-slug -source)
                                                 :post-number (:post-number -source)})
                                {:style {:color (:ui-color -source)}}          
                                [:h4.thread-title (:thread -source)])]
        [:div.col-md-4 (link-to (routes :subforum {:id (:subforum-id -source) 
                                                   :slug (:subforum-slug -source)})
                                {:style {:color (:ui-color -source)}}
                                [:h5 (:subforum-group -source)
                                     " / "
                                     (:subforum -source)])]]
      [:div.body (partials/html-from-markdown (:body -source))]
      [:div.row.footer 
       [:div.col-md-10 [:a {:href (routes/hs-route 
                                    :person {:hacker-school-id (:hacker-school-id -source)})}
                           (:author -source)]]
       [:div.col-md-2  (link-to (routes :thread {:id (:thread-id -source)
                                                 :slug (:thread-slug -source)
                                                 })
                                {:style {:color (:ui-color -source)}}          
                                "View thread ->")]]])))



(defn search [owner]
  (let [_ (println "I am being called")
        input (om/get-node owner "search-query")
        query (-> input .-value)]
    (routes/redirect-to (routes :search {:query query}))))

(defn suggest [query]
  (controller/dispatch :update-search-suggestions query))

(defcomponent search-box [app owner]
  (display-name [_] "Search Box")

  (render [_]
    (html
      [:form.form-inline 
        {:name "search-form"
         :onSubmit (fn [e]
                     (.preventDefault e)
                     (search owner))}
          [:input.form-control {:ref "search-query" 
                                :type "text" 
                                :style {:height "26px"}
                                :onKeyUp (fn [e] (suggest (.. e -target -value)))}]])))

(defcomponent suggestions [app owner]
  (display-name [_] "Search suggestions")
  (render [_]
    (println app)))

(defcomponent search-results [{:keys [search] :as app} owner]
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

 
