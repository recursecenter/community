(ns community.components.shared
  (:require [community.routes :as routes]
            [community.state :as state]
            [community.api :as api]
            [community.util :refer-macros [p <?]]
            [community.util.autocomplete :as ac]
            [community.util.selection-list :as selection-list]
            [community.partials :as partials]
            [om.core :as om]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :refer-macros [html]]
            [goog.style]
            [cljs.core.async :as async])
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
                                       {:keys [passthrough on-change focus?]}]
  (display-name [_] "AutocompletingTextArea")

  (init-state [_]
    {:ac-selections []
     :focused? false
     :new-cursor-pos nil
     :should-drop-down? false})

  (did-mount [_]
    (when focus?
      (.focus (om/get-node owner "textarea"))))

  (did-update [_ _ _]
    (let [textarea (om/get-node owner "textarea")]
      (when-let [new-cursor-pos (:new-cursor-pos (om/get-state owner))]
        (ac/set-cursor-position textarea new-cursor-pos)
        (om/set-state! owner :new-cursor-pos nil))

      (let [textarea-top (.-y (goog.style/getClientPosition textarea))]
        (om/set-state! owner :should-drop-down? (< textarea-top 120)))))

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
              (insert [selected]
                (let [ac (-> (ac/autocompleter value (ac/cursor-position (om/get-node owner "textarea")))
                             (ac/insert selected {:marker "@"}))]
                  (on-change (ac/value ac))
                  (om/set-state! owner :ac-selections [])
                  (om/set-state! owner :new-cursor-pos (ac/cursor-position ac))))
              (insert-selected [e]
                (insert (selection-list/selected ac-selections)))
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
            [:ul.dropdown-menu {:ref "dropdown-menu"}
             (for [{selected? :selected? v :value} ac-selections]
               [:li {:class (if selected? "active")}
                [:a {:href "#" :onClick (fn [e]
                                          (.preventDefault e)
                                          (insert v))}
                 v]])]
            [:textarea (merge passthrough
                              {:value value
                               :ref "textarea"
                               :onClick set-ac-selections
                               :onKeyUp set-ac-selections
                               :onKeyDown handle-autocomplete-action
                               :onBlur #(go
                                          ;; HACK: We have to wait before setting :focused?
                                          ;; to false to give the dropdown items' :onClick
                                          ;; a chance to run before being rendered away.
                                          ;; We then have to check that the textarea hasn't
                                          ;; been focused in the meantime.
                                          ;; >:( Seriously, React?
                                          (async/<! (async/timeout 200))
                                          (when-not (= (.-activeElement js/document) (om/get-node owner "textarea"))
                                            (om/set-state! owner :focused? false)))
                               :onFocus #(om/set-state! owner :focused? true)
                               :onChange (fn [e]
                                           (on-change (.. e -target -value)))})]]])))))

(defcomponent broadcast-group-picker [{:keys [broadcast-groups]} owner {:keys [on-toggle]}]
  (display-name [_] "BroadcastGroupPicker")

  (render [_]
    (html
      (let [toggle (fn [id e]
                     (.preventDefault e)
                     (on-toggle id))]
        [:div.btn-group.dropup
         [:div.dropdown
          [:button.btn.btn-link.btn-xs.dropdown-toggle {:type "button" :data-toggle "dropdown"}
           "Add broadcast group"]
          [:ul.dropdown-menu.broadcast-group-list
           (for [{:keys [name id]} (filter (complement :selected?) broadcast-groups)]
             [:li [:a {:href "#" :onClick (partial toggle id)}
                   name]])]
          (for [{:keys [name id]} (filter :selected? broadcast-groups)]
            [:span.label.label-info.broadcast-label {:onClick (partial toggle id)}
             "× " name])]]))))

(defcomponent subscription-info [{:keys [subscribed reason] :as subscription} owner {:keys [reason?] :or {reason? true}}]
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
         [:button.btn.btn-link.subscription-button {:onClick toggle-subscription-status}
          (if subscribed
            [:span [:span.glyphicon.glyphicon-volume-off] " Unsubscribe"]
            [:span [:span.glyphicon.glyphicon-volume-up] " Subscribe"])]
         (when reason?
           [:p.subscription-reason reason])]))))

(defcomponent post-preview [{:keys [post autocomplete-users]}]
  (display-name [_] "PostPreview")

  (render [_]
    (html
      [:div.post.post-preview
       [:div.post-body
        (partials/html-from-markdown
         (partials/wrap-mentions (:body post) autocomplete-users))]])))

(defn tab [owner id body]
  (html
    [:li {:class (when (= id (om/get-state owner :active-tab-id)) "active")}
     [:a {:href "#" :onClick (fn [e]
                               (.preventDefault e)
                               (om/set-state! owner :active-tab-id id))}
      body]]))

(defcomponent tabbed-panel [{:keys [tabs props]} owner]
  (display-name [_] "TabbedPanel")

  (init-state [_]
    {:active-tab-id (-> tabs first :id)})

  (render-state [_ {:keys [active-tab-id]}]
    (html
      [:div.panel.panel-default
       [:div.panel-heading.community-heading
        [:ul.nav.nav-tabs.community-tabs
         (for [{:keys [id body]} tabs]
           (tab owner id body))]]
       [:div.panel-body
        (let [view-fn (-> (filter #(= active-tab-id (:id %)) tabs)
                          first
                          :view-fn)]
          (view-fn props))]])))
