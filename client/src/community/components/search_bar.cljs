(ns community.components.search-bar
  (:require [community.controller :as controller]
            [community.routes :as routes :refer [routes]]
            [community.util.selection-list :as sl]
            [community.util.search :refer [search!]]
            [om.core :as om]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :refer-macros [html]]))


(def ENTER 13)
(def UP_ARROW 38)
(def DOWN_ARROW 40)
(def TAB 9)
(def ESC 27)


(def key->search-filter {:users :author :threads :thread :subforums :subforum})


(defn result-set->suggestion-data [search-filter result-set]
  (map-indexed (fn [i {:keys [text payload]}]
                 {:search-filter search-filter
                  :text text
                  :id (:id payload)
                  :slug (:slug payload)
                  :count i})
               result-set))


(defn results->suggestions-display [results query-str]
  (mapcat (fn [[key result-set]]
            (when (not (empty? result-set))
              (let [search-filter (key->search-filter key)]
                (result-set->suggestion-data search-filter result-set))))
          results))


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


(defn complete-and-respond! [query-data selected]
  (cond (and (nil? selected) (not (empty? (:text query-data))))
        (search! query-data)

        (= :author (:search-filter selected))
        (search! (complete-suggestion query-data selected))

        (contains? #{:thread :subforum} (:search-filter selected))
        (jump-to-page selected)))


(defn suggestions-dropdown [{:keys [query-data suggestions show-suggestions?]}]
  (html
    [:ol
     {:id "suggestions" :ref "suggestions"
      :style (when-not (and show-suggestions?
                            (not (empty? (:text query-data)))
                            (not (empty? suggestions)))
               {:display "none"})}
     (for [{:keys [selected? value] :as suggestion} suggestions]
       [:li {:class (when selected? "selected")
             :onMouseDown #(complete-and-respond! query-data value)
             :onTouchStart #(complete-and-respond! query-data value)
             :data-search-filter (when (= 0 (:count value))
                                   (name (:search-filter value)))}
        (:text value)])]))


(defn search-input-box [{:keys [query-data suggestions]} owner]
  (letfn [(select! [direction]
            (om/set-state! owner :suggestions (sl/select direction suggestions)))
          (query-text-change! [e]
            (let [target (.-target e)
                  text (.-value target)]
              (om/update-state! owner :query-data #(assoc % :text text))
              ;; Only update search suggestions if the query text
              ;; hasn't changed for 100ms
              (when (not= "" text)
                (js/setTimeout
                 #(when (= text (.-value target))
                    (controller/dispatch :update-search-suggestions text))
                 100))))
          (blur! []
            (.blur (om/get-node owner "search-query")))
          (handle-key-down! [e]
            (let [keycode (.-keyCode e)]
              (when (contains? #{UP_ARROW DOWN_ARROW ENTER TAB ESC} keycode)
                (.preventDefault e)
                (condp = keycode
                  DOWN_ARROW (select! :next)
                  UP_ARROW (select! :prev)
                  ENTER (do
                          (complete-and-respond! query-data (sl/selected suggestions))
                          (blur!))
                  TAB (select! :next)
                  ESC (if (sl/selected suggestions)
                        (om/set-state! owner :suggestions (sl/unselect suggestions))
                        (blur!))))))]
    (html
      [:form
       {:id "search-form"
        :name "search-form"}
       [:i {:id "search-icon" :class "fa fa-search"}]
       [:input.form-control {:ref "search-query"
                             :type "search"
                             :id "search-box"
                             :value (:text query-data)
                             :onFocus #(om/set-state! owner :show-suggestions? true)
                             :onBlur #(om/set-state! owner :show-suggestions? false)
                             :onChange query-text-change!
                             :onKeyDown handle-key-down!}]])))


(defn suggestion-sl [suggestions query-str]
  (-> suggestions
      (results->suggestions-display query-str)
      (sl/selection-list nil)))


(def initial-query-state
  {:text ""
   :page 1
   :filters {:author nil :subforum nil :thread nil}})


(defcomponent search-bar [app owner]
  (display-name [_] "Autocomplete")

  (init-state [_]
    {:query-data initial-query-state
     :show-suggestions? false
     :suggestions (suggestion-sl (:suggestions app) (:query-str app))})

  (will-receive-props [_ next-props]
    (when (not= (:query-str next-props) (:query-str (om/get-props owner)))
      (om/set-state! owner
                     :suggestions (suggestion-sl (:suggestions next-props) (:query-str next-props)))))

  (render-state [_ state]
    (html
      [:div {:id "search"}
       (search-input-box state owner)
       (suggestions-dropdown state)])))
