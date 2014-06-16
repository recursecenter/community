(ns community.models
  (:require [clojure.string :as str]
            [community.util :as util :refer-macros [p]]))

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

(declare notification thread post user subforum subforum-group)

(defmulti notification :type)

(defmethod notification "mention" [mention]
  (-> mention
      (update-in [:thread] thread)))

(defn user [{:as api-data
             :keys [first-name last-name notifications]}]
  (assoc api-data
         :name (str first-name " " last-name)
         :notifications (mapv notification notifications)))

(defn post [api-data]
  (-> api-data
      (assoc :persisted? true)))

(defn thread [{:as api-data
               :keys [title posts id autocomplete-users]}]
  (-> api-data
      (assoc :slug (slug title))
      (assoc :posts (mapv post posts))
      (assoc :autocomplete-users (mapv user autocomplete-users))))

(defn subforum [{:as api-data
                 :keys [name threads autocomplete-users]}]
  (-> api-data
      (assoc :slug (slug name))
      (assoc :new-thread (empty-thread))
      (assoc :threads (mapv thread threads))
      (assoc :autocomplete-users (mapv user autocomplete-users))))

(defn subforum-group [{:as api-data
                       :keys [subforums]}]
  (assoc api-data :subforums
         (mapv subforum subforums)))

(defn names->mention-regexp [names]
  (let [names-with-pipes (str/join "|" (map #(str "(" % ")") names))]
    (js/RegExp. (str "@(" names-with-pipes ")") "gi")))

(defn parse-mentions [{:keys [body]} users]
  (let [regexp (names->mention-regexp (map :name users))
        downcased-name->user (into {} (for [user users] [(.toLowerCase (:name user)) user]))
        downcased-names-mentioned (map #(.toLowerCase (.substring % 1)) (.match body regexp)) ]
    (mapv downcased-name->user downcased-names-mentioned)))

(defn with-mentions [post users]
  (assoc post :mentions (parse-mentions post users)))
