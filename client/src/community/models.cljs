(ns community.models
  (:require [clojure.string :as str]
            [community.util :as util :refer-macros [p]]
            [community.util.transform :refer-macros [deftransformer deftransform]]))

(defn empty-post [thread-id]
  {:body ""
   :thread-id thread-id
   :persisted? false
   :announce-to #{}})

(defn empty-thread []
  {:title ""
   :body ""})

(defn toggle-announce-to [announce-to id]
  (if (contains? announce-to id)
    (disj announce-to id)
    (conj announce-to id)))

;; Assumption: these functions are only run on data that came from the
;; server, so they must have been already persisted.

(deftransformer api->model)

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
