(ns community.models)

(defn slug
  "\"Dave's awesome subforum!\" => \"daves-awesome-subforum\""
  [name]
  (-> name
      (.toLowerCase)
      (.replace (js/RegExp. "[^a-zA-Z0-9- ]" "g") "")
      (.replace (js/RegExp. " " "g") "-")))

(defn subforum [{:as api-data
                 :keys [name]}]
  (-> api-data
      (assoc :slug (slug name))))

(defn subforum-group [{:as api-data
                       :keys [subforums]}]
  api-data)





;;;;;; prototype models
(comment

  ;; app-state
  {:route-data route-data
   :current-user current-user
   :subforum-groups subforum-groups
   :subforums subforums}

  ;; current-user
  {:first-name "" :last-name "" :email "" :avatar ""}

  ;; subforum-groups
  [{:name "Subforum group 1"
    :subforums-ids [1 2 3 ...]}
   ...]

  ;; subforums
  [{:name "Subforum 1"
    :unread? true
    :description ""
    :threads threads}
   ...]

  ;; threads
  [{:name "Thread 1"
    :author user1
    :last-updated Date
    :unread? true
    :posts posts}
   ...]

  ;; user1
  like current-user

  ;; posts
  [{:author user1
    :content "important discussion"
    :last-modified Date
    :created-at Date}
   ...]



  )
