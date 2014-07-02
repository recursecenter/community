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
           [:span {:ref "label"
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
        [:div
         [:h1 "Settings"]
         [:div.row
          [:div.settings-container
           [:div.panel.panel-default
            [:div.panel-heading [:strong "Notifications"]]
            [:div.panel-body
             (->live-checkbox settings
               {:opts {:submit submit-setting
                       :key :email-on-mention
                       :label [:span "Email me when I get " [:strong "@mentioned"] "."]}})]]]]]))))
