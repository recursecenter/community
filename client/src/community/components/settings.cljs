(ns community.components.settings
  (:require [community.api :as api]
            [community.util :refer-macros [<?]]
            [om.core :as om]
            [om-tools.core :refer-macros [defcomponent]]
            [sablono.core :refer-macros [html]])
  (:require-macros [cljs.core.async.macros :refer [go]]))

(defcomponent live-checkbox [data owner {:keys [key label submit]}]
  (display-name [_] "LiveCheckbox")

  (init-state [_]
    {:last-update-successful? nil})

  (render-state [_ {:keys [last-update-successful?]}]
    (letfn [(change-handler [e]
              (let [old-value (get @data key)
                    new-value (not old-value)]
                (om/update! data key new-value)
                (go
                  (let [success? (<! (submit key new-value))]
                    (om/set-state! owner :last-update-successful? success?)
                    (js/setTimeout #(om/set-state! owner :last-update-successful? nil) 300)
                    (when-not success?
                      (om/update! data key old-value))))))]
      (html
        [:form
         [:div.checkbox
          [:label
           [:input {:type "checkbox"
                    :checked (get data key)
                    :onChange change-handler}]
           [:div {:ref "label"
                  :class (case last-update-successful?
                           true "bg-success"
                           false "bg-danger"
                           nil)}
            label]]]]))))

(defn submit-setting [setting new-value]
  (go
    (try
      (<? (api/update-settings {setting new-value}))
      true
      (catch ExceptionInfo e
        false))))

(defcomponent settings [{:keys [current-user] :as app} owner]
  (display-name [_] "Settings")

  (render [_]
    (let [settings (:settings current-user)]
      (html
        [:div#settings-view
         [:h1 "Settings"]
         [:div.row
          [:div.settings-container
           [:div.panel.panel-default
            [:div.panel-heading [:strong "Email notifications"]]
            [:div.panel-body
             (->live-checkbox settings
               {:opts {:submit submit-setting
                       :key :email-on-mention
                       :label [:span "Email me when I get " [:span.at-mention "@mentioned"] "."]}})]]
           [:div.panel.panel-default
            [:div.panel-heading [:strong "Subscriptions"]]
            [:div.panel-body
             (->live-checkbox settings
               {:opts {:submit submit-setting
                       :key :subscribe-on-create
                       :label [:span "Subscribe me to threads I create."]}})
             (->live-checkbox settings
               {:opts {:submit submit-setting
                       :key :subscribe-when-mentioned
                       :label [:span "Subscribe me to threads I am " [:span.at-mention "@mentioned"] " in."]}})
             (->live-checkbox settings
               {:opts {:submit submit-setting
                       :key :subscribe-new-thread-in-subscribed-subforum
                       :label [:div "Subscribe me to new threads created in subforums I'm subscribed to."
                               [:p.small "You will only be subscribed to new threads that are broadcast to subforum subscribers."]]}})]]]]]))))
