(ns community.models
  (:require [community.util :as util :refer-macros [p]]))

(defn slug
  "\"Dave's awesome subforum!\" => \"daves-awesome-subforum\""
  [name]
  (-> name
      (.toLowerCase)
      (.replace (js/RegExp. "[^a-zA-Z0-9- ]" "g") "")
      (.replace (js/RegExp. "\\s+" "g") "-")))

(defn empty-post [thread-id]
  {:body ""
   :thread-id thread-id
   :persisted? false})

(defn empty-thread []
  {:title ""
   :body ""})

;; Assumption: these functions are only run on data that came from the
;; server, so they must have been already persisted.

(defn post [api-data]
  (-> api-data
      (assoc :persisted? true)))

(defn thread [{:as api-data
               :keys [title posts id]}]
  (-> api-data
      (assoc :slug (slug title))
      (assoc :posts (mapv post posts))))

(defn subforum [{:as api-data
                 :keys [name threads]}]
  (-> api-data
      (assoc :slug (slug name))
      (assoc :new-thread (empty-thread))
      (assoc :threads (mapv thread threads))))

(defn subforum-group [{:as api-data
                       :keys [subforums]}]
  (assoc api-data :subforums
         (mapv subforum subforums)))

(defmulti notification :type)

(defmethod notification "mention" [mention]
  (-> mention
      (update-in [:thread] thread)))

(defn user [{:as api-data
             :keys [first-name last-name notifications]}]
  (assoc api-data
         :name (str first-name " " last-name)
         :notifications (mapv notification notifications)))
