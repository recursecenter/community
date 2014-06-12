(ns community.components.shared
  (:require [community.routes :as routes]
            [community.util :refer-macros [p]]
            [om.core :as om]
            [sablono.core :refer-macros [html]]))

(defn page-not-found-component [app owner]
  (reify
    om/IDisplayName
    (display-name [_] "PageNotFound")

    om/IRender
    (render [this]
      (html [:h1 "Page not found"]))))

(defn resizing-textarea-component [{:keys [value]} owner {:keys [passthrough focus?]}]
  (reify
    om/IDisplayName
    (display-name [_] "ResizingTextArea")

    om/IDidMount
    (did-mount [this]
      (let [textarea (om/get-node owner)
            scroll-height (.-scrollHeight textarea)
            height (if (> scroll-height 200)
                     200
                     scroll-height)]
        (set! (.. textarea -style -height) (str height "px"))
        (when focus?
          (.focus textarea))))

    om/IRender
    (render [this]
      (html [:textarea (merge {:value value} passthrough)]))))

(defn get-search-string [s pos]
  (loop [i (dec pos)]
    (cond (= i -1) nil
          (= (.charAt s i) "@") (.substring s (inc i) pos)
          :else (recur (dec i)))))

(defn starts-with [s substr]
  (prn s)
  (prn substr)
  (p (zero? (.indexOf s substr))))

(defn results-for-search-string [search-string autocomplete-list]
  (take 4 (filter #(starts-with % search-string) autocomplete-list)))

(defn autocompleting-textarea-component [{:keys [value autocomplete-list]} owner {:keys [passthrough]}]
  (reify
    om/IDisplayName
    (display-name [_] "AutocompletingTextArea")

    om/IInitState
    (init-state [_]
      {:autocomplete-results []})

    om/IDidUpdate
    (did-update [_ _ _]
      (let [textarea (om/get-node owner "textarea")
            cursor-position (.-selectionStart textarea)
            search-string (get-search-string value cursor-position)]
        (om/set-state!
          owner
          :autocomplete-results
          (results-for-search-string search-string autocomplete-list))))

    om/IRenderState
    (render-state [_ {:keys [autocomplete-results]}]
      (html
        [:div
         (when (not (empty? autocomplete-results))
           [:ul
            (for [value autocomplete-results]
              [:li
               [:a {:href "#"} value]])])

         [:textarea (merge passthrough
                           {:value value
                            :ref "textarea"})]]))))
