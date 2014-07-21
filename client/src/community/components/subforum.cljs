(ns community.components.subforum
  (:require [community.state :as state]
            [community.util :as util :refer-macros [<? p]]
            [community.api :as api]
            [community.models :as models]
            [community.location :refer [redirect-to]]
            [community.partials :as partials :refer [link-to]]
            [community.routes :refer [routes]]
            [community.components.shared :as shared]
            [om.core :as om]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :as html :refer-macros [html]]
            [cljs.core.async :as async])
  (:require-macros [cljs.core.async.macros :refer [go go-loop]]))

(defcomponent new-thread [{:as subforum :keys [broadcast-groups]} owner]
  (display-name [_] "NewThread")

  (init-state [this]
    {:c-draft (async/chan 1)
     :form-disabled? false
     :errors #{}})

  (will-mount [this]
    (let [{:keys [c-draft]} (om/get-state owner)]
      (go-loop []
        (when-let [draft (<! c-draft)]
          (try
            (let [{:keys [id autocomplete-users]} @subforum
                  new-thread (<? (api/new-thread id (models/with-mentions draft autocomplete-users)))]
              (redirect-to (routes :thread new-thread)))

            (catch ExceptionInfo e
              (om/set-state! owner :form-disabled? false)
              (let [e-data (ex-data e)]
                (om/update-state! owner :errors #(conj % (state/error-message e-data))))))

          (recur)))))

  (will-unmount [this]
    (async/close! (:c-draft (om/get-state owner))))

  (render [this]
    (let [{:keys [form-disabled? c-draft errors]} (om/get-state owner)]
      (html
        [:div.panel
         {:class (if (empty? errors) "panel-default" "panel-danger")}
         [:div.panel-heading
          [:span.title-caps "New thread"]
          (when (not (empty? errors))
            (map (fn [e] [:div e]) errors))]
         [:div.panel-body
          [:form {:onSubmit (fn [e]
                              (.preventDefault e)
                              (when-not form-disabled?
                                (async/put! c-draft (:new-thread @subforum))
                                (om/set-state! owner :form-disabled? true)))}
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
                                   :class "form-control"
                                   :placeholder "Compose your post..."}}})]
           [:button.btn.btn-default {:type "submit"
                                     :disabled form-disabled?}
            "Create thread"]]]]))))

(defn update-subforum! [app]
  (go
    (try
      (let [subforum (<? (api/subforum (-> @app :route-data :id)))]
        (om/update! app :subforum subforum)
        (state/remove-errors! :ajax))

      (catch ExceptionInfo e
        (let [e-data (ex-data e)]
          (if (== 404 (:status e-data))
            (om/update! app [:route-data :route] :page-not-found)
            (state/add-error! (:error-info e-data))))))))

(defcomponent subforum [{:keys [route-data subforum] :as app}
                        owner]
  (display-name [_] "Subforum")

  (did-mount [_]
    (update-subforum! app))

  (will-receive-props [_ next-props]
    (let [last-props (om/get-props owner)]
      (when (not= (:route-data next-props) (:route-data last-props))
        (update-subforum! app))))

  (render [this]
    (html
      (if (= (str (:id subforum)) (:id route-data))
        [:div
         [:ol.breadcrumb
            [:li (link-to (routes :index) "Community")]
            [:li.active (:name subforum)]]
         (partials/title (:name subforum) "New thread")
         (if (empty? (:threads subforum))
           [:div.alert.alert-info "There are no threads - create the first one!"]
           [:table.table.threads-view
            [:tbody
             (for [{:keys [id slug title created-by] :as thread} (:threads subforum)]
               [:tr {:key id :class (if (:unread thread) "unread")}
                [:td.name created-by]
                [:td.title (link-to (routes :thread thread) title)]
                [:td.timestamp (util/human-format-time (:marked-unread-at thread))]])]])
         (->new-thread subforum)]
        [:div.push-down]))))
