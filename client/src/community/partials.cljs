(ns community.partials
  (:require [community.location :as location]
            [sablono.core :refer-macros [html]]
            [markdown.core :as md]
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

;; TODO sanitize with goog.labs.html.Sanitizer
(defn html-from-markdown [md-string]
  (let [safe-html-string (md/mdToHtml (goog.string/htmlEscape md-string))]
    (dom/div #js {:dangerouslySetInnerHTML #js {:__html safe-html-string}})))
