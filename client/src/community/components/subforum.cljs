(ns community.components.subforum
  (:require [community.util :as util :refer-macros [<? p]]
            [community.api :as api]
            [community.location :refer [redirect-to]]
            [community.partials :refer [link-to]]
            [community.routes :refer [routes]]
            [om.core :as om]
            [sablono.core :as html :refer-macros [html]]
            [cljs.core.async :as async])
  (:require-macros [cljs.core.async.macros :refer [go go-loop]]))

(defn new-thread-component [subforum owner]
  (reify
    om/IDisplayName
    (display-name [_] "NewThread")

    om/IInitState
    (init-state [this]
      {:c-draft (async/chan 1)
       :form-disabled? false})

    om/IWillMount
    (will-mount [this]
      (let [{:keys [c-draft]} (om/get-state owner)]
        (go-loop []
          (when-let [draft (<! c-draft)]
            (let [new-thread (<? (api/new-thread (:id @subforum) draft))]
              (redirect-to (routes :thread new-thread)))
            ;; TODO: deal with failing validations (including re-enable the form)
            (recur)))))

    om/IWillUnmount
    (will-unmount [this]
      (async/close! (:c-draft (om/get-state owner))))

    om/IRender
    (render [this]
      (let [{:keys [form-disabled? c-draft]} (om/get-state owner)]
        (html
         [:div.panel.panel-default
          [:div.panel-heading
           [:h4 "New thread"]]
          [:div.panel-body
           [:form {:onSubmit (fn [e]
                               (.preventDefault e)
                               (when-not form-disabled?
                                 (async/put! c-draft (:new-thread @subforum))
                                 (om/set-state! owner :form-disabled? true)))}
            [:div.form-group
             [:label {:for "thread-title"} "Title"]
             [:input#thread-title.form-control
              {:type "text"
               :name "thread[title]"
               :onChange (fn [e]
                           (om/update! subforum [:new-thread :title]
                                       (-> e .-target .-value)))}]]
            [:div.form-group
             [:label {:for "post-body"} "Body"]
             [:textarea#post-body.form-control
              {:value (get-in subforum [:new-thread :body])
               :name "post[body]"
               :onChange (fn [e]
                           (om/update! subforum [:new-thread :body]
                                       (-> e .-target .-value)))}]]
            [:button.btn.btn-default {:type "submit"
                                      :disabled form-disabled?}
             "Create thread"]]]])))))

(defn subforum-component [{:keys [route-data subforum] :as app}
                          owner]
  (reify
    om/IDisplayName
    (display-name [_] "Subforum")

    om/IDidMount
    (did-mount [this]
      (go
        (try
          (let [subforum (<? (api/subforum (:id @route-data)))]
            (om/update! app :subforum subforum))

          (catch ExceptionInfo e
            ;; TODO: display an error modal
            (if (== 404 (:status (ex-data e)))
              (om/update! app [:route-data :route] :page-not-found)
              ;; TODO: generic error component
              (throw e))))))

    om/IRender
    (render [this]
      (html
       (if subforum
         [:div
          [:h1 (:name subforum)]
          [:table.table.table-striped
           [:thead
            [:tr [:th "Topic"] [:th "Created by"] [:th "Last updated"]]]
           [:tbody
            (for [{:keys [id slug title created-by] :as thread} (:threads subforum)]
              [:tr {:key id}
               [:td (link-to (routes :thread thread) title)]
               [:td created-by]
               [:td (p (util/time-ago-in-words (:updated-at thread)))]])]]
          (om/build new-thread-component subforum)]
         [:h2 "loading..."])))))
