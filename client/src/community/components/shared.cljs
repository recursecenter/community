(ns community.components.shared
  (:require [community.routes :as routes]
            [om.core :as om]
            [sablono.core :refer-macros [html]]))

(def ^:private alert-classes
  {:success "alert-success"
   :info "alert-info"
   :warning "alert-warning"
   :danger "alert-danger"})

(defn alert-component [{:keys [body]} owner {:keys [on-close alert-class]}]
  (reify
    om/IDisplayName
    (display-name [_] "Alert")

    om/IInitState
    (init-state [_]
      {:closed? false})

    om/IRenderState
    (render-state [this {:keys [closed?]}]
      (html
       (if closed?
         [:div]
         [:div.row
          [:div.alert {:class alert-class}
           [:button.close {:type "button"
                           :onClick (or on-close #(om/set-state! owner :closed? true))}
            "×"]
           body]])))))

(defn alert
  "Returns a closeable alert component. Alert levels can
  be :success, :info, :warning, :danger.

  The alert will disappear on close if no on-close callback is
  provided. If one is provided, it's the callers responsibility to
  cause the alert not to be rendered."
  ([level body]
     (alert level {} body))
  ([level {:as opts :keys [on-close]} body]
     (om/build alert-component
               {:body body}
               {:opts (assoc opts :alert-class (get alert-classes level))})))

(alert :success {:on-close #()}
  [:foo-bar-baz])

(defn page-not-found-component [app owner]
  (reify
    om/IDisplayName
    (display-name [_] "PageNotFound")

    om/IRender
    (render [this]
      (html [:h1 "Page not found"]))))

(defn resizing-textarea-component [{:keys [content]} owner {:keys [passthrough focus?]}]
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
      (html [:textarea (merge {:value content} passthrough)]))))
