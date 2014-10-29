(ns community.models
  (:require [clojure.string :as str]
            [community.util :as util :refer-macros [p]]
            [community.util.transform :refer-macros [deftransformer deftransform]]))

(defn empty-post [thread-id]
  {:body ""
   :thread-id thread-id
   :persisted? false
   :broadcast-to #{"Subscribers"}})

(defn empty-thread []
  {:title ""
   :body ""
   :broadcast-to #{"Subscribers"}})

(defn toggle-broadcast-to [broadcast-to id]
  (if (contains? broadcast-to id)
    (disj broadcast-to id)
    (conj broadcast-to id)))

;; Assumption: these functions are only run on data that came from the
;; server, so they must have been already persisted.

(deftransformer api->model)

(deftransform api->model :roles roles
  (set roles))

(deftransform api->model :thread thread
  (assoc thread
    :new-post (empty-post (:id thread))))

(deftransform api->model {:single [:user :mentioned-by] :many :autocomplete-users}
  {:as user :keys [first-name last-name]}
  (assoc user
    :name (or (:name user) (str first-name " " last-name))))

(deftransform api->model {:single :post :many :posts}
  post
  (assoc post :persisted? true))

(deftransform api->model {:single :subforum :many :subforums}
  {:as subforum :keys [name threads]}
  (assoc subforum
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

(defn replace-mentions [body users replace-fn]
  (let [regexp (names->mention-regexp (map :name users))]
    (.replace body regexp replace-fn)))

;;; User roles

(defn admin? [user]
  (contains? (:roles user) "admin"))
