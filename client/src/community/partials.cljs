(ns community.partials
  (:require [community.location :as location]
            [community.util :refer-macros [p]]
            [sablono.core :refer-macros [html]]
            [om.dom :as dom]
            [goog.window :as window]
            [goog.string.html.htmlSanitize]))

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

;;; Marked configuration (Markdown parsing/rendering)
(.setOptions js/marked
  #js {:highlight (fn [code]
                    (.. js/hljs (highlightAuto code) -value))})

;; TODO: use google's caja html sanitizer instead
(defn html-from-markdown [md-string]
  ;; htmlSanitize accepts a "url policy" as the optional second
  ;; argument; a function to be applied to every URL attribute value,
  ;; e.g. src and href. We simply allow all URLs.
  (let [safe-html-string (goog.string.html.htmlSanitize (js/marked md-string) identity)]
    (dom/div #js {:dangerouslySetInnerHTML #js {:__html safe-html-string}})))

(defn scroll-to-bottom []
  (set! (.-scrollTop js/document.body)
        (.-scrollHeight js/document.body)))

(defn title [title-text button-text]
  (html
    [:div.row
     [:div.topic [:h1 title-text]]
     [:div.topic-button
      [:button.btn.btn-new.btn-sm
       {:onClick (fn [e]
                   (scroll-to-bottom)
                   (.focus (.querySelector js/document "[data-new-anchor]")))}
       button-text]]]))
