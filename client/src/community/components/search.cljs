(ns community.components.search
  (:require [community.controller :as controller]
            [community.models :as models]
            [community.api :as api]
            [community.routes :as routes :refer [routes]]
            [community.components.shared :as shared]
            [community.util :as util :refer-macros [<? p]]
            [community.util.selection-list :as sl]
            [community.partials :as partials :refer [link-to]]
            [om.core :as om]
            [om.dom :as dom]
            [cljs.core.async :as async :refer [chan <! >! close! put! alts!]]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :refer-macros [html]]
            [clojure.string :as str])
  (:require-macros [cljs.core.async.macros :refer [go go-loop]]))

(def key->search-filter {:users :author :threads :thread :subforums :subforum})

(defn result-set->suggestion-data [search-filter result-set]
  (map (fn [{:as result :keys [text payload]} counter]
         {:search-filter search-filter 
          :text text 
          :id (:id payload) 
          :slug (:slug payload) 
          :count counter})
       result-set (range (count result-set))))

(defn results->suggestions-display [results query-str]
  (let [filter-suggestions 
          (mapcat (fn [key result-set]
            (when (not (empty? result-set))
              (let [search-filter (key->search-filter key)
                    suggestion-data (result-set->suggestion-data search-filter result-set)]
                   suggestion-data)))
            (keys results) (vals results))]
        filter-suggestions))

(def ENTER 13)
(def UP_ARROW 38)
(def DOWN_ARROW 40)
(def TAB 9)
(def ESC 27)

(defn display [show]
  (if show {} {:display "none"}))

(defn clear! [query-data]
  (reset! query-data {:text ""
                      :filters {:author nil :subforum nil :thread nil}}))

(defn jump-to-page [{:keys [search-filter text id slug]}]
  (routes/redirect-to 
    (condp = search-filter
      :thread (routes :thread {:id id :slug slug})
      :subforum (routes :subforum {:id id :slug slug})
      nil)))

(defn complete-suggestion [query-data suggestion]
  (-> query-data
      (assoc-in [:filters (:search-filter suggestion)] (:text suggestion))
      (assoc :text "")))

(defn search! [query-data]
  (let [query-param-str (->> (for [[filter-name value] (:filters query-data)
                             :when value]
                         (str (name filter-name) "=" value))
                       (str/join "&"))]
    (routes/redirect-to (str (routes :search {:query (:text query-data)})
                             "?" query-param-str))))

(defn complete-and-respond! [query-data selected]
  (cond 
    (= :author (:search-filter selected))
      (search! (complete-suggestion query-data selected))    
    (contains? #{:thread :subforum} (:search-filter selected))
      (jump-to-page selected)))

(defcomponent suggestions-view [app owner]
  (display-name [_] "Search suggestions")
  (render-state [_ {:keys [query-data suggestions show-suggestions?]}]
    (html
     [:ol
      {:id "suggestions" :ref "suggestions"
       :style (display (and show-suggestions? (not (empty? (:text query-data)))
                                              (not (empty? suggestions))))}
        (for [{:keys [selected? value] :as suggestion} suggestions]
          [:li {:class (when selected? "selected")
                :onClick (fn [e]
                           (.preventDefault e)
                           (complete-and-respond! query-data value))
                :data-search-filter (when (= 0 (:count value)) (name (:search-filter value)))} 
            (:text value)])])))

(defcomponent input-view 
  [{:keys [query-data show-suggestions! select! complete! query-text-change! complete-and-respond! clear!]}
                          owner]
  (display-name [_] "Search Input")

  (render [_]
    (html
       [:form
        {:id "search-form"
         :name "search-form"
         :onSubmit (fn [e]
                     (.preventDefault e)
                     (complete-and-respond!))}
        [:i {:id "search-icon" :class "fa fa-search"}]
        [:input.form-control {:ref "search-query"
                              :type "search"
                              :id "search-box"
                              :value (:text query-data)
                              :onFocus #(show-suggestions! true)
                              ;; TODO: do we need this timeout without core.async?
                              :onBlur (fn [e] (js/setTimeout #(show-suggestions! false) 100))
                              :onChange (fn [e]
                                          (query-text-change! (.. e -target -value)))
                              :onKeyDown (fn [e]
                                           (let [keycode (.-keyCode e)]
                                             (when (contains? #{UP_ARROW DOWN_ARROW ENTER} keycode)
                                               (.preventDefault e)
                                               (condp = keycode
                                                 DOWN_ARROW (select! :next)
                                                 UP_ARROW (select! :prev)
                                                 ENTER (do
                                                         (complete-and-respond!)
                                                         (clear!))))))}]])))
(def initial-query-state {:text ""
                          :filters {:author nil :subforum nil :thread nil}})

(defn suggestion-sl [suggestions query-str]
  (-> suggestions
      (results->suggestions-display query-str)
      (sl/selection-list true)))

(defcomponent autocomplete [app owner]
  (display-name [_] "Autocomplete")

  (init-state [_]
    {:query-data initial-query-state 
     :show-suggestions? false
     :suggestions (suggestion-sl (:suggestions app) (:query-str app))})

  (will-receive-props [_ next-props]
    (when (not= (:query-str next-props) (:query-str (om/get-props owner)))
      (om/set-state! owner
                     :suggestions (suggestion-sl (:suggestions next-props) (:query-str next-props)))))

  (render-state [_ {:as state :keys [query-data suggestions]}]
    (html
     [:div {:id "search"}
      (->input-view {:query-data query-data
                     :show-suggestions! #(om/set-state! owner :show-suggestions? %)
                     :select! #(om/set-state! owner :suggestions (sl/select % suggestions))
                     :complete! (fn []
                                  (let [s (sl/selected suggestions)]
                                    (om/set-state! owner :query-data (complete-suggestion query-data s))))
                     :query-text-change! (fn [text]
                                           (om/update-state! owner :query-data #(assoc % :text text))
                                           (controller/dispatch :update-search-suggestions text))
                     :complete-and-respond! (fn []
                                                (if-let [selected (sl/selected suggestions)]
                                                  (complete-and-respond! query-data selected)
                                                  (search! query-data)))
                     :clear! (fn []
                               (om/set-state! owner :query-data initial-query-state))})
      (->suggestions-view app {:state state})])))

(defcomponent result [{:keys [post author thread subforum highlight] :as result}]
  (display-name [_] "Result")

  (render [_]
    (html
     [:div.row.search-result
      [:div.metadata {:data-ui-color (:ui-color subforum)}
       [:div.author 
        [:a {:href (routes/hs-route :person {:hacker-school-id (:hacker-school-id author)})}
            (:name author)]]
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
        (partials/html-from-markdown highlight)]]])))

(defcomponent search-results [{:keys [search] :as app} owner]
  (display-name [_] "Search Results")

  (render [_]
    (let [results (:results search)
          metadata (:metadata search)]
      (if (empty? results)
        (html
         [:div
          "Sorry, there were no matching results for this search."])
        (html
         [:div {:id "search-results-view"}
          [:div.query "Search Results for : " ]
          [:div.results (map (partial ->result) results)]])))))
