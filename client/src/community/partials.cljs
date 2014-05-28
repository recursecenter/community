(ns community.partials
  (:require [community.location :as location]
            [community.util :refer-macros [p]]
            [sablono.core :refer-macros [html]]
            [om.dom :as dom]
            [goog.window :as window]
            [goog.string]))

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

;; TODO: externs for advanced compilation
(defn html-from-markdown [md-string]
  (let [safe-html-string (.toHTML js/markdown (goog.string/htmlEscape md-string))]
    (dom/div #js {:dangerouslySetInnerHTML #js {:__html safe-html-string}})))
