(ns community.components.subforum
  (:require [community.state :as state]
            [community.controller :as controller]
            [community.util :as util :refer-macros [<? p]]
            [community.models :as models]
            [community.partials :as partials :refer [link-to]]
            [community.routes :as routes :refer [routes]]
            [community.components.shared :as shared]
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
       [:button.btn.btn-default {:type "submit"
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
       (partials/title (:name subforum) "New thread")
       (shared/->subscription-info (:subscription subforum))
       (if (empty? (:threads subforum))
         [:div.alert.alert-info "There are no threads - create the first one!"]
         [:table.table.threads-view
          [:tbody
           (for [{:keys [id slug title created-by] :as thread} (:threads subforum)]
             [:tr {:key id :class (if (:unread thread) "unread")}
              [:td.name created-by]
              [:td.title (link-to (routes :thread thread) title)]
              [:td.timestamp (util/human-format-time (:updated-at thread))]])]])
       (shared/->tabbed-panel
        {:tabs [{:id :new-thread :body "Compose thread" :view-fn ->new-thread}
                {:id :preview :body "Preview" :view-fn thread-post-preview}]
         :props subforum})])))
