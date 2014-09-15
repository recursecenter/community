(ns community.components.subforum
  (:require [community.state :as state]
            [community.controller :as controller]
            [community.util :as util :refer-macros [<? p]]
            [community.models :as models]
            [community.partials :as partials :refer [link-to]]
            [community.routes :as routes :refer [routes]]
            [community.components.shared :as shared]
            [community.components.subforum-info :refer [->subforum-info]]
            [om.core :as om]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :as html :refer-macros [html]]
            [cljs.core.async :as async])
  (:require-macros [cljs.core.async.macros :refer [go go-loop]]))

(defcomponent new-thread [{:as subforum :keys [broadcast-groups submitting? errors]} owner]
  (display-name [_] "NewThread")

  (render [this]
    (html
      [:form {:onSubmit (fn [e]
                          (.preventDefault e)
                          (when-not submitting?
                            (controller/dispatch :new-thread (:new-thread @subforum))))}
       (when (not (empty? errors))
         [:div (map (fn [e] [:p.text-danger e]) errors)])
       [:div.form-group
        (let [broadcast-to (:broadcast-to (:new-thread subforum))]
          (shared/->broadcast-group-picker
           {:broadcast-groups (mapv #(assoc % :selected? (contains? broadcast-to (:id %)))
                                    broadcast-groups)}
           {:opts {:on-toggle (fn [id]
                                (om/transact! subforum [:new-thread :broadcast-to]
                                              #(models/toggle-broadcast-to % id)))}}))]
       [:div.form-group
        [:label.hidden {:for "thread-title"} "Title"]
        [:input#thread-title.form-control
         {:type "text"
          :value (:title (:new-thread subforum))
          :placeholder "Thread title"
          :data-new-anchor true
          :onChange (fn [e]
                      (om/update! subforum [:new-thread :title]
                                  (-> e .-target .-value)))}]]
       [:div.form-group
        [:label.hidden {:for "post-body"} "Body"]
        (shared/->autocompleting-textarea
         {:value (get-in subforum [:new-thread :body])
          :autocomplete-list (mapv :name (:autocomplete-users subforum))}
         {:opts {:on-change #(om/update! subforum [:new-thread :body] %)
                 :passthrough {:id "post-body"
                               :class ["form-control" "post-textarea"]
                               :placeholder "Compose your post..."}}})]
       [:button.btn.btn-default.btn-sm {:type "submit"
                                        :disabled submitting?}
        "Create thread"]])))

(defn thread-post-preview [subforum]
  (shared/->post-preview {:post (:new-thread subforum)
                          :autocomplete-users (:autocomplete-users subforum)}))

(defcomponent subforum [{:keys [route-data subforum] :as app}
                        owner]
  (display-name [_] "Subforum")

  (render [this]
    (html
      [:div#subforum-view
       [:div.row.no-side-margin
        [:div.subscribe (shared/->subscription-info (:subscription subforum))]
        [:div.new-item-button (partials/new-anchor-button "New thread" {:class ["btn" "btn-link"]})]]

       [:div.row.no-side-margin
        (if (empty? (:threads subforum))
          [:div.alert.alert-info "There are no threads - create the first one!"]
          (->subforum-info subforum {:opts {:nowrap? false
                                            :title-link? false}}))]

       [:div.row.no-side-margin
        [:div.new-thread
         (shared/->tabbed-panel
          {:tabs [{:id :new-thread :body "Compose thread" :view-fn ->new-thread}
                  {:id :preview :body "Preview" :view-fn thread-post-preview}]
           :props subforum})]]])))
