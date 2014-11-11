(ns community.components.search-bar
  (:require [community.controller :as controller]
            [community.routes :as routes :refer [routes]]
            [community.util.selection-list :as sl]
            [community.util.search :as search-util :refer [search!]]
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


(defn results->suggestions-display [results]
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


(defn complete-suggestion [search-query suggestion]
  (-> search-query
      (assoc-in [:filters (:search-filter suggestion)] (:text suggestion))
      (assoc :text "")))


(defn complete-and-respond! [search-query selected]
  (cond (and (nil? selected) (not (empty? (:text search-query))))
        (search! search-query)

        (= :author (:search-filter selected))
        (search! (complete-suggestion search-query selected))

        (contains? #{:thread :subforum} (:search-filter selected))
        (jump-to-page selected)))


(defn suggestions-dropdown [app owner]
  (let [{:keys [suggestions show-suggestions?]} (om/get-state owner)
        search-query (:search-query app)]
    (html
     [:ol
      {:id "suggestions" :ref "suggestions"
       :style (when-not (and show-suggestions?
                             (not (empty? (:text search-query)))
                             (not (empty? suggestions)))
                {:display "none"})}
      (for [{:keys [selected? value] :as suggestion} suggestions]
        [:li {:class (when selected? "selected")
              :onMouseDown #(complete-and-respond! search-query value)
              :onTouchStart #(complete-and-respond! search-query value)
              :data-search-filter (when (= 0 (:count value))
                                    (name (:search-filter value)))}
         (:text value)])])))


(defn search-input-box [app owner]
  (let [suggestions (om/get-state owner :suggestions)
        search-query (:search-query app)]
    (letfn [(select! [direction]
              (om/set-state! owner :suggestions (sl/select direction suggestions)))

            (query-text-change! [e]
              (let [target (.-target e)
                    text (.-value target)]
                (om/transact! app :search-query #(assoc % :text text))
                ;; Only update search suggestions if the query text
                ;; hasn't changed for 100ms
                (when (not= "" text)
                  (js/setTimeout
                   #(when (= text (get-in @app [:search-query :text]))
                      (controller/dispatch :update-search-suggestions text))
                   100))))

            (blur! []
              (.blur (om/get-node owner "search-box")))

            (handle-key-down! [e]
              (let [keycode (.-keyCode e)]
                (when (contains? #{UP_ARROW DOWN_ARROW ENTER TAB ESC} keycode)
                  (.preventDefault e)
                  (condp = keycode
                    DOWN_ARROW
                    (select! :next)

                    UP_ARROW
                    (select! :prev)

                    ENTER
                    (let [query (search-util/query-from-text (:text @search-query))]
                      (om/transact! app #(assoc % :search-query query))
                      (complete-and-respond! query (sl/selected suggestions))
                      (blur!))

                    TAB
                    (select! :next)

                    ESC
                    (if (sl/selected suggestions)
                      (om/set-state! owner :suggestions (sl/unselect suggestions))
                      (blur!))))))]
      (html
       [:form#search-form
        [:i#search-icon.fa.fa-search]
        [:input#search-box.form-control
         {:ref "search-box"
          :type "search"
          :value (:text search-query)
          :onFocus #(om/set-state! owner :show-suggestions? true)
          :onBlur #(om/set-state! owner :show-suggestions? false)
          :onChange query-text-change!
          :onKeyDown handle-key-down!}]]))))


(defn suggestion-sl [suggestions]
  (-> suggestions
      results->suggestions-display
      (sl/selection-list nil)))


(defcomponent search-bar [app owner]
  (display-name [_] "SearchBar")

  (init-state [_]
    {:show-suggestions? false
     :suggestions (suggestion-sl (:suggestions app))})

  (will-receive-props [_ next-props]
    (when (not= (:suggestions next-props) (:suggestions (om/get-props owner)))
      (om/set-state! owner :suggestions (suggestion-sl (:suggestions next-props)))))

  (render-state [_ state]
    (html
      [:div#search
       (search-input-box app owner)
       (suggestions-dropdown app owner)])))
