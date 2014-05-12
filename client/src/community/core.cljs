(ns community.core
  (:require [community.api]
            [om.core :as om]
            [om.dom :as dom]
            [cljs.core.async :as async])
  (:require-macros [cljs.core.async.macros :refer [go]]))

(enable-console-print!)

;;;;;; prototype app-state
(comment

  ;; app-state
  {:current-user current-user
   :subforum-groups subforum-groups}

  ;; current-user
  {:first-name "" :last-name "" :email "" :avatar ""}

  ;; subforum-groups
  [{:name "Subforum group 1"
    :subforums subforums}
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

(def app-state
  (atom {:current-user nil
         :subforum-groups nil}))

(defn *forum-view [{:as app
                    :keys [current-user subforum-groups]}
                   owner]
  (reify
    om/IRender
    (render [this]
      (dom/div nil
        (dom/h1 nil (str "Hey " (or (get current-user "first_name")
                                    "fella")))
        (when subforum-groups
          (apply dom/div #js{:id "subforum-groups"}
                 (for [group subforum-groups]
                   (dom/div nil (:name group)))))))

    om/IDidMount
    (did-mount [this]
      (community.api/GET "/users/me"
        {:handler (fn [user-data]
                    (om/update! app :current-user user-data))
         :error-handler (fn [{:keys [status] :as res}]
                          (if (== status 403)
                            (set! (.-location js/document) "/login")
                            (prn res)))})
      (let [soonTM #(om/update! app :subforum-groups
                                [{:name "Group1"}
                                 {:name "Group2"}
                                 {:name "Group3"}])]
        (js/setTimeout soonTM 1000)))))

(js/$
 #(om/root *forum-view
           app-state
           {:target (.getElementById js/document "app")}))
