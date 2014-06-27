(ns community.models
  (:require [clojure.string :as str]
            [community.util :as util :refer-macros [p]]
            [community.util.transform :refer-macros [deftransformer deftransform]]))

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

(deftransformer api->model)

(deftransform api->model :notifications notifications
  (mapv #(api->model :notification %) notifications))

(deftransform api->model :user {:as user :keys [first-name last-name]}
  (assoc user
    :name (str first-name " " last-name)))

(deftransform api->model :posts posts
  (mapv #(api->model :post %) posts))

(deftransform api->model :post post
  (assoc post :persisted? true))

(deftransform api->model :threads threads
  (mapv #(api->model :thread %) threads))

(deftransform api->model :thread {:as thread :keys [title]}
  (assoc thread :slug (slug title)))

(deftransform api->model :autocomplete-users users
  (mapv #(api->model :user %) users))

(deftransform api->model :subforums subforums
  (mapv #(api->model :subforum %) subforums))

(deftransform api->model :subforum {:as subforum :keys [name threads]}
  (assoc subforum
    :slug (slug name)
    :new-thread (empty-thread)))

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
