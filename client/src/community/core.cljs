(ns community.core
  (:require [community.state :refer [app-state]]
            [community.routes :as routes]
            [community.location :as location :refer [redirect-to]]
            [community.components.app :as app]
            [community.components.index :as index]
            [community.components.subforum :as subforum]
            [community.components.thread :as thread]
            [community.components.shared :as shared]
            [om.core :as om]))

(enable-console-print!)

;;; Route dispatch and browser location config
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defmethod routes/dispatch :index          [_] index/index-component)
(defmethod routes/dispatch :subforum       [_] subforum/subforum-component)
(defmethod routes/dispatch :thread         [_] thread/thread-component)
(defmethod routes/dispatch :page-not-found [_] shared/page-not-found-component)
(defmethod routes/dispatch :default        [_] shared/page-not-found-component)

(location/init-location! app-state)

;;; Exports
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(def ^:private print-builds? true)

(defn ^:export init-app
  "Mounts the om application onto target element."
  [target]
  (om/root app/app-component
           app-state
           {:target target
            :instrument (fn [component _ _]
                          (when print-builds? (println "Building" (.-name component)))
                          ::om/pass)}))
