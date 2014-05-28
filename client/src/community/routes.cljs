(ns community.routes
  (:require [community.util.routing :as r]))

;;; App routes

(def routes
  (r/routes
    (r/route :index [])
    (r/route :subforum ["f" :slug :id])
    (r/route :thread ["t" :slug :id])))

(defn set-route! [app]
  (let [route (routes (-> js/document .-location .-pathname))]
    (swap! app assoc :route-data route)))

(defmulti dispatch :route)

;;; HS routes

(def hs-root "https://www.hackerschool.com")

(def hs-routes
  (r/routes
    (r/route :person ["people" :hacker-school-id])))

(defn hs-route
  [& args]
  (str hs-root (apply hs-routes args)))
