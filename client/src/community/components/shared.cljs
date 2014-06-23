(ns community.components.shared
  (:require [community.routes :as routes]
            [community.util :refer-macros [p]]
            [community.util.autocomplete :as ac]
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
      (let [menu-showing? (and focused? (seq ac-selections))
            control-keys #{"ArrowUp" "ArrowDown" "Enter" "Tab"}]
        (letfn [(set-ac-selections [e]
                  ;; Don't set ac selections again when e.g. someone's
                  ;; scrolling through the results they already see
                  (when-not (and menu-showing? (= "keyup" (.-type e)) (control-keys (.-key e)))
                    (let [ac-textarea (ac/->MockTextarea value (.-selectionStart (.-target e)))]
                      (->> (ac/possibilities ac-textarea autocomplete-list {:marker "@"})
                           (take 4)
                           (selection-list/selection-list)
                           (om/set-state! owner :ac-selections)))))
                (scroll [direction]
                  (let [next-or-prev (case direction "ArrowDown" :next "ArrowUp" :prev)]
                    (om/set-state! owner :ac-selections
                      (selection-list/select next-or-prev ac-selections))))
                (insert-selected [e]
                  (let [selected (selection-list/selected ac-selections)
                        ac-textarea (-> (ac/->MockTextarea value (.-selectionStart (.-target e)))
                                        (ac/insert selected {:marker "@"}))]
                    (on-change (ac/value ac-textarea))
                    (om/set-state! owner :ac-selections [])
                    (om/set-state! owner :new-cursor-pos (ac/cursor-position ac-textarea))))
                (handle-autocomplete-action [e]
                  (when menu-showing?
                    (when-let [key (control-keys (.-key e))]
                      (.preventDefault e)
                      (case key
                        ("ArrowUp" "ArrowDown") (scroll key)
                        ("Enter" "Tab") (insert-selected e)))))]
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
                                 :onClick set-ac-selections
                                 :onKeyUp set-ac-selections
                                 :onKeyDown handle-autocomplete-action
                                 :onBlur #(om/set-state! owner :focused? false)
                                 :onFocus #(om/set-state! owner :focused? true)
                                 :onChange (fn [e]
                                             (on-change (.. e -target -value)))})]]]))))

    om/IDidUpdate
    (did-update [_ _ _]
      (let [textarea (om/get-node owner "textarea")]
        (when-let [new-cursor-pos (:new-cursor-pos (om/get-state owner))]
          (ac/set-cursor-position textarea new-cursor-pos)
          (om/set-state! owner :new-cursor-pos nil))

        (let [textarea-top (.-y (goog.style/getClientPosition textarea))]
          (om/set-state! owner :should-drop-down? (< textarea-top 120)))))))
