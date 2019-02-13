(ns community.partials
  (:require [community.routes :as routes]
            [community.models :as models]
            [community.util :refer-macros [p]]
            [community.api.push :as push-api]
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
                                  (when (and routes/pushstate-enabled
                                             (not (push-api/ws-closed?)))
                                    (.preventDefault e)
                                    (if (routes/open-in-new-window? e)
                                      (window/open path)
                                      (routes/redirect-to path))
                                    nil))})
       body])))

;;; Marked configuration (Markdown parsing/rendering)
(.setOptions js/marked
  #js {:highlight (fn [code]
                    (.. js/hljs (highlightAuto code) -value))
       :gfm true
       :tables true
       :smartLists false})

(defn url-policy [s]
  (if (some #(= (.indexOf s %) 0) ["http:" "https:" "mailto:"])
    s
    ""))

;; TODO: use google's caja html sanitizer instead
(defn html-from-markdown [md-string]
  ;; htmlSanitize accepts a "url policy" as the optional second
  ;; argument; a function to be applied to every URL attribute value,
  ;; e.g. src and href.
  (let [safe-html-string (goog.string.html.htmlSanitize (js/marked md-string) url-policy)]
    (dom/div #js {:dangerouslySetInnerHTML #js {:__html safe-html-string}})))

(defn scroll-to-bottom []
  (set! (.-scrollTop js/document.body)
        (.-scrollHeight js/document.body)))

(defn new-anchor-button
  ([button-text]
     (new-anchor-button button-text {}))
  ([button-text attrs]
     (html
       [:button (merge attrs
                       {:onClick (fn [e]
                                   (scroll-to-bottom)
                                   (.focus (.querySelector js/document "[data-new-anchor]")))})
        button-text])))

(defn loading-icon [color]
  (html
    [:div.push-down.loading
     [:i.fa.fa-spinner.fa-spin.fa-2x {:style {:color color}}]]))

(defn wrap-mentions
  "Wraps @mentions in a post body in <span class=\"at-mention\">"
  [body users]
  (models/replace-mentions body users (fn [name]
                                        (str "<span class=\"at-mention\">" name "</span>"))))

(defn markdown-help []
  (html
   [:div.markdown-help
    [:a.help-link
     {:target "_blank"
      :href "https://guides.github.com/features/mastering-markdown/"}
     "Markdown cheat sheet"]]))
