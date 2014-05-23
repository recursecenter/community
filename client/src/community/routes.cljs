(ns community.routes
  (:require [community.util.routing :as r]))

(def routes
  (r/routes
    (r/route :index [])
    (r/route :subforum ["f" :slug :id])
    (r/route :thread ["t" :slug :id])))

(defn set-route! [app]
  (let [route (routes (-> js/document .-location .-pathname))]
    (swap! app assoc :route-data route)))

(defmulti dispatch :route)
