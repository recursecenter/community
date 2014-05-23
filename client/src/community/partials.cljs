(ns community.partials
  (:require [community.location :as location]
            [sablono.core :refer-macros [html]]
            [goog.window :as window]))

(defn link-to [path & body]
  (html
   [:a {:href path
        :onClick (fn [e]
                   (when location/pushstate-enabled
                     (.preventDefault e)
                     (if (location/open-in-new-window? e)
                       (window/open path)
                       (location/redirect-to path))))}
    body]))
