(ns community.routes
  (:require [community.util.routing :as r]))

;;; App routes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(def routes
  (r/routes
    (r/route :index [])
    (r/route :settings ["settings"])
    (r/route :subforum ["f" :slug :id])
    (r/route :thread   ["t" :slug :id :post-number])
    (r/route :thread   ["t" :slug :id])
    (r/route :search   ["s" :query])
    (r/route :search   ["s"])))

(defmulti dispatch :route)

;;; HS routes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(def hs-root "https://www.recurse.com")

(def hs-routes
  (r/routes
    (r/route :person ["people" :hacker-school-id])))

(defn hs-route
  [& args]
  (str hs-root (apply hs-routes args)))

;;; Browser location
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(def pushstate-enabled
  (boolean (.-pushState js/history)))

(defn redirect-to [path]
  (.pushState js/history nil nil path)
  (.dispatchEvent js/window (js/Event. "popstate")))

(defn open-in-new-window? [click-e]
  (or (.-metaKey click-e)
      (.-ctrlKey click-e)
      ;; middle click
      (= 1 (.-button click-e))))
