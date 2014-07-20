(ns community.components.shared
  (:require [community.routes :as routes]
            [community.state :as state]
            [community.api :as api]
            [community.util :refer-macros [p <?]]
            [community.util.autocomplete :as ac]
            [community.util.selection-list :as selection-list]
            [om.core :as om]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :refer-macros [html]]
            [goog.style])
  (:require-macros [cljs.core.async.macros :refer [go]]))

(defcomponent page-not-found [app owner]
  (display-name [_] "PageNotFound")
  (render [this]
    (html [:h1 "Page not found"])))

(defcomponent resizing-textarea [{:keys [value]}
                                           owner
                                           {:keys [passthrough focus?]}]
  (display-name [_] "ResizingTextArea")

  (did-mount [this]
    (let [textarea (om/get-node owner)
          scroll-height (.-scrollHeight textarea)
          height (if (> scroll-height 200)
                   200
                   scroll-height)]
      (set! (.. textarea -style -height) (str height "px"))
      (when focus?
        (.focus textarea))))

  (render [this]
    (html [:textarea (merge {:value value} passthrough)])))

(defcomponent autocompleting-textarea [{:as state :keys [value autocomplete-list]}
                                       owner
                                       {:keys [passthrough on-change]}]
  (display-name [_] "AutocompletingTextArea")

  (init-state [_]
    {:ac-selections []
     :focused? false
     :new-cursor-pos nil
     :should-drop-down? false})

  (render-state [_ {:keys [focused? ac-selections should-drop-down?]}]
    (let [menu-showing? (and focused? (seq ac-selections))
          control-keys #{"ArrowUp" "ArrowDown" "Enter" "Tab"}]
      (letfn [(set-ac-selections [e]
                ;; HACK: update value before possible causing a local
                ;; re-render (see #71)
                (on-change (.. e -target -value))
                ;; Don't set ac selections again when e.g. someone's
                ;; scrolling through the results they already see
                (when-not (and menu-showing? (= "keyup" (.-type e)) (control-keys (.-key e)))
                  (let [ac (ac/autocompleter value (ac/cursor-position (.-target e)))]
                    (->> (ac/possibilities ac autocomplete-list {:marker "@"})
                         (take 4)
                         (selection-list/selection-list)
                         (om/set-state! owner :ac-selections)))))
              (scroll [direction]
                (let [next-or-prev (case direction "ArrowDown" :next "ArrowUp" :prev)]
                  (om/set-state! owner :ac-selections
                                 (selection-list/select next-or-prev ac-selections))))
              (insert-selected [e]
                (let [selected (selection-list/selected ac-selections)
                      ac (-> (ac/autocompleter value (ac/cursor-position (.-target e)))
                             (ac/insert selected {:marker "@"}))]
                  (on-change (ac/value ac))
                  (om/set-state! owner :ac-selections [])
                  (om/set-state! owner :new-cursor-pos (ac/cursor-position ac))))
              (handle-autocomplete-action [e]
                ;; HACK: update value before possible causing a local
                ;; re-render (see #71)
                (on-change (.. e -target -value))

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

  (did-update [_ _ _]
    (let [textarea (om/get-node owner "textarea")]
      (when-let [new-cursor-pos (:new-cursor-pos (om/get-state owner))]
        (ac/set-cursor-position textarea new-cursor-pos)
        (om/set-state! owner :new-cursor-pos nil))

      (let [textarea-top (.-y (goog.style/getClientPosition textarea))]
        (om/set-state! owner :should-drop-down? (< textarea-top 120))))))

(defcomponent broadcast-group-picker [{:keys [broadcast-groups]} owner {:keys [on-toggle]}]
  (display-name [_] "BroadcastGroupPicker")

  (render [_]
    (html
      (let [toggle (fn [id e]
                     (.preventDefault e)
                     (on-toggle id))]
        [:div.btn-group.dropup
         [:div.dropdown
          [:button.btn.btn-default.btn-xs.dropdown-toggle {:type "button" :data-toggle "dropdown"}
           [:span.glyphicon.glyphicon-plus.small] " broadcast"]
          [:ul.dropdown-menu
           (for [{:keys [name id]} (filter (complement :selected?) broadcast-groups)]
             [:li [:a {:href "#" :onClick (partial toggle id)}
                   name]])]
          (for [{:keys [name id]} (filter :selected? broadcast-groups)]
            [:span.label.label-default.broadcast-label {:onClick (partial toggle id)}
             "× " name])]]))))

(defcomponent subscription-info [{:keys [subscribed reason] :as subscription} owner]
  (display-name [_] "SubscriptionInfo")

  (render [_]
    (letfn [(toggle-subscription-status [e]
              (go
                (try
                  (let [res (<? (if subscribed
                                  (api/unsubscribe @subscription)
                                  (api/subscribe @subscription)))]
                    (om/transact! subscription [] #(merge % res)))
                  (state/remove-errors! :ajax)
                  (catch ExceptionInfo e
                    (state/add-error! [:ajax :generic])))))]
      (html
        [:div.subscription-info
         [:button.btn.btn-default.btn-small {:onClick toggle-subscription-status}
          (if subscribed
            [:span [:span.glyphicon.glyphicon-volume-off] " Unsubscribe"]
            [:span [:span.glyphicon.glyphicon-volume-up] " Subscribe"])]
         [:p.small.text-muted reason]]))))
