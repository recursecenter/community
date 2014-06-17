(ns community.location
  (:require [community.routes :as routes :refer [routes]]
            [sablono.core :as html :refer-macros [html]]))

(def pushstate-enabled
  (boolean (.-pushState js/history)))

(defn redirect-to [path]
  (.pushState js/history nil nil path)
  (.dispatchEvent js/window (js/Event. "popstate")))

(defn ^:private open-in-new-window? [click-e]
  (or (.-metaKey click-e) (.-ctrlKey click-e)))

(defn init-location! [app-state]
  (routes/set-route! app-state)
  (.addEventListener js/window "popstate" #(routes/set-route! app-state)))
