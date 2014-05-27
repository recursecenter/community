(ns community.partials
  (:require [community.location :as location]
            [sablono.core :refer-macros [html]]
            [goog.window :as window]))

(defn link-to [path & args]
  (let [[opts body] (if (map? (first args))
                      [(first args) (rest args)]
                      [{} args])]
    (html
      [:a (merge opts {:href path
                       :onClick (fn [e]
                                  (when location/pushstate-enabled
                                    (.preventDefault e)
                                    (if (location/open-in-new-window? e)
                                      (window/open path)
                                      (location/redirect-to path))))})
       body])))
