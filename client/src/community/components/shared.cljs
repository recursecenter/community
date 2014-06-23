(ns community.components.shared
  (:require [community.routes :as routes]
            [community.util :refer-macros [p]]
            [community.util.selection-list :as selection-list]
            [om.core :as om]
            [sablono.core :refer-macros [html]]
            [goog.style]))

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

(defn get-search-string-start [s pos]
  (loop [i (dec pos)]
    (cond (= i -1) nil
          (= (.charAt s i) "@") (inc i)
          :else (recur (dec i)))))

(defn get-search-string [s pos]
  (when-let [start (get-search-string-start s pos)]
    (.substring s start pos)))

(defn starts-with [s substr]
  (zero? (.indexOf s substr)))

;; TODO: Right now we do a full scan of the search string on every
;; keypress. If I'm editing a very long post, that could potentially
;; be too expensive. We could pass in a third parameter which is the
;; max length we'll scan backwards, and can be the length of the
;; longest string in the autocomplete list.
(defn results-for-search-string [search-string autocomplete-list]
  (when search-string
    (take 4 (filter #(starts-with
                      (.toLowerCase %)
                      (.toLowerCase search-string))
                    autocomplete-list))))

(defn get-autocomplete-results [e value autocomplete-list]
  (let [cursor-position (.-selectionStart (.-target e))
        search-string (get-search-string value cursor-position)]
    (results-for-search-string search-string autocomplete-list)))

(defn autocompleting-textarea-component [{:as state :keys [value autocomplete-list]}
                                         owner
                                         {:keys [passthrough on-change]}]
  (reify
    om/IDisplayName
    (display-name [_] "AutocompletingTextArea")

    om/IInitState
    (init-state [_]
      {:ac-selections []
       :focused? false
       :new-cursor-pos nil
       :should-drop-down? false})

    om/IRenderState
    (render-state [_ {:keys [focused? ac-selections should-drop-down?]}]
      (prn (seq ac-selections))
      (let [menu-showing? (and focused? (seq ac-selections))
            control-keys #{"ArrowUp" "ArrowDown" "Enter" "Tab"}]
        (letfn [(set-autocomplete-results [e]
                  ;; Don't set autocomplete results again when e.g. someone's
                  ;; scrolling through the results they already see
                  (when-not (and menu-showing? (= "keyup" (.-type e)) (control-keys (.-key e)))
                    (om/set-state! owner :ac-selections
                                   (selection-list/selection-list
                                    (get-autocomplete-results e value autocomplete-list)))))
                (scroll [direction]
                  (let [next-or-prev (case direction "ArrowDown" :next "ArrowUp" :prev)]
                    (om/set-state! owner :ac-selections
                      (selection-list/select next-or-prev ac-selections))))
                (insert-active [e]
                  (let [selected (selection-list/selected ac-selections)
                        pos (.-selectionStart (.-target e))
                        start (get-search-string-start value pos)
                        inserted-value (str selected " ")
                        new-cursor-pos (+ start (count inserted-value))
                        new-value (str (.substring value 0 start)
                                       inserted-value
                                       (.substring value pos))]
                    (on-change new-value)
                    (om/set-state! owner :ac-selections [])
                    (om/set-state! owner :new-cursor-pos new-cursor-pos)))
                (handle-autocomplete-action [e]
                  (when menu-showing?
                    (when-let [key (control-keys (.-key e))]
                      (.preventDefault e)
                      (case key
                        ("ArrowUp" "ArrowDown") (scroll key)
                        ("Enter" "Tab") (insert-active e)))))]
          (html
            [:div
             [:div.btn-group.full-size {:class [(if menu-showing? "open")
                                                (if should-drop-down? "dropdown" "dropup")]}
              [:ul.dropdown-menu
               (for [{:keys [value selected?]} ac-selections]
                 [:li {:class (if selected? "active")}
                  [:a {:href "#"} value]])]
              [:textarea (merge passthrough
                                {:value value
                                 :ref "textarea"
                                 :onClick set-autocomplete-results
                                 :onKeyUp set-autocomplete-results
                                 :onKeyDown handle-autocomplete-action
                                 :onBlur #(om/set-state! owner :focused? false)
                                 :onFocus #(om/set-state! owner :focused? true)
                                 :onChange (fn [e]
                                             (on-change (.. e -target -value)))})]]]))))

    om/IDidUpdate
    (did-update [_ _ _]
      (let [textarea (om/get-node owner "textarea")]
        (when-let [new-cursor-pos (:new-cursor-pos (om/get-state owner))]
          (.setSelectionRange textarea new-cursor-pos new-cursor-pos)
          (om/set-state! owner :new-cursor-pos nil))

        (let [textarea-top (.-y (goog.style/getClientPosition textarea))]
          (om/set-state! owner :should-drop-down? (< textarea-top 120)))))))
