(ns community.components.thread
  (:require [community.util :refer-macros [<? p]]
            [community.api :as api]
            [community.models :as models]
            [community.partials :as partials]
            [community.routes :as routes]
            [community.components.shared :as shared]
            [om.core :as om]
            [sablono.core :refer-macros [html]]
            [cljs.core.async :as async]
            [clojure.string :as str])
  (:require-macros [cljs.core.async.macros :refer [go go-loop]]))

(defn post-form-component [{:as props :keys [after-persisted cancel-edit autocomplete-users]} owner]
  (reify
    om/IDisplayName
    (display-name [_] "PostForm")

    om/IInitState
    (init-state [this]
      {:init-post (:init-post props)
       :post (:init-post props)
       :c-post (async/chan 1)
       :form-disabled? false
       :errors #{}})

    om/IWillMount
    (will-mount [this]
      (let [{:keys [c-post]} (om/get-state owner)]
        (go-loop []
          (when-let [post (<! c-post)]
            (try
              (let [post-with-mentions (models/with-mentions post @autocomplete-users)
                    new-post (<? (if (:persisted? post)
                                   (api/update-post post-with-mentions)
                                   (api/new-post post-with-mentions)))]
                (om/set-state! owner :form-disabled? false)
                (om/set-state! owner :errors #{})
                (after-persisted new-post
                                 #(om/set-state! owner :post (:init-post (om/get-state owner)))))
              (catch ExceptionInfo e
                (om/set-state! owner :form-disabled? false)
                (let [e-data (ex-data e)]
                  (om/update-state! owner :errors #(conj % (:message e-data))))))
            (recur)))))

    om/IWillReceiveProps
    (will-receive-props [this next-props]
      (let [init-post (:init-post next-props)]
        (om/set-state! owner :init-post init-post)
        (om/update-state! owner :post #(assoc % :thread-id (:thread-id init-post)))))

    om/IWillUnmount
    (will-unmount [this]
      (async/close! (:c-post (om/get-state owner))))

    om/IRender
    (render [this]
      (let [{:keys [form-disabled? c-post post errors]} (om/get-state owner)]
        (html
          [:div.panel {:class (if (empty? errors) "panel-default" "panel-danger")}
           (if (not (empty? errors))
             [:div.panel-heading (map (fn [e] [:div e]) errors)])
           [:div.panel-body
            [:form {:onSubmit (fn [e]
                                (.preventDefault e)
                                (when-not form-disabled?
                                  (async/put! c-post post)
                                  (om/set-state! owner :form-disabled? true)))}
             (let [post-body-id (str "post-body-" (or (:id post) "new"))]
               [:div.form-group
                [:label.hide {:for post-body-id} "Body"]
                (om/build shared/autocompleting-textarea-component
                          {:value (:body post)
                           :autocomplete-list (mapv :name autocomplete-users)}
                          {:opts {:focus? (:persisted? post)
                                  :on-change #(om/set-state! owner [:post :body] %)
                                  :passthrough
                                  {:id post-body-id
                                   :class "form-control"
                                   :name "post[body]"}}})])
             [:button.btn.btn-default {:type "submit"
                                       :disabled form-disabled?}
              (if (:persisted? post) "Update" "Post")]
             (when (:persisted? post)
               [:button.close {:type "button"
                               :onClick cancel-edit}
                "x"])]]])))))

(defn post-component [{:keys [post autocomplete-users]} owner]
  (reify
    om/IDisplayName
    (display-name [_] "Post")

    om/IInitState
    (init-state [this]
      {:editing? false})

    om/IRenderState
    (render-state [this {:keys [editing?]}]
      (html
       [:li.post {:key (:id post)}
        [:div.row
         [:div.post-author
          [:img.post-profile-image
           {:src (-> post :author :avatar-url)
            :width "50"       ;TODO: request different image sizes
            }]
          [:a {:href (routes/hs-route :person (:author post))}
           (-> post :author :name)]]
         [:div.post-body
          (if editing?
            (om/build post-form-component {:init-post (om/value post)
                                           :autocomplete-users autocomplete-users
                                           :after-persisted (fn [new-post reset-form!]
                                                              (om/set-state! owner :editing? false)
                                                              (doseq [[k v] new-post]
                                                                (om/update! post k v)))
                                           :cancel-edit (fn []
                                                          (om/set-state! owner :editing? false))})

            (partials/html-from-markdown (:body post)))]]
        [:div.row
          [:div.post-controls
           (when (and (:editable post) (not editing?))
             [:a {:href "#"
                  :onClick (fn [e]
                             (.preventDefault e)
                             (om/set-state! owner :editing? true))}
              "Edit"])]]]))))

(defn reverse-find-index
  [pred v]
  (first (for [[i el] (map-indexed vector (rseq v))
               :when (pred el)]
           (- (count v) i 1))))

(defn update-post!
  "Assumes :created-at is always increasing."
  [app post]
  (let [posts (-> @app :thread :posts)
        created-at (:created-at post)]
    (if (or (empty? posts) (> created-at (:created-at (peek posts))))
      (om/transact! app [:thread :posts] #(conj % post))
      (let [i (reverse-find-index #(= (:id %) (:id post)) posts)]
        (om/transact! app [:thread :posts] #(assoc % i post))))))

(defn update-thread! [app]
  (go
    (try
      (let [thread (<? (api/thread (:id (:route-data @app))))]
        (om/update! app :thread thread)
        (om/update! app :errors #{})
        thread)

      (catch ExceptionInfo e
        (let [e-data (ex-data e)]
          (if (== 404 (:status e))
            (om/update! app [:route-data :route] :page-not-found)
            (om/transact! app :errors #(conj % (:message e-data)))))))))

(defn start-thread-subscription! [thread-id app owner]
  (when api/subscriptions-enabled?
    (go
      (let [[thread-feed unsubscribe!] (api/subscribe! {:feed :thread :id thread-id})]
        (om/set-state! owner :ws-unsubscribe! unsubscribe!)
        (loop []
          (when-let [message (<! thread-feed)]
            (update-post! app (models/post (:data message)))
            (recur)))))))

(defn stop-thread-subscription! [owner]
  (let [{:keys [ws-unsubscribe!]} (om/get-state owner)]
    (when ws-unsubscribe!
      (ws-unsubscribe!))))

(defn thread-component [{:keys [route-data thread] :as app} owner]
  (reify
    om/IDisplayName
    (display-name [_] "Thread")

    om/IInitState
    (init-state [this]
      {:ws-unsubscribe! nil})

    om/IDidMount
    (did-mount [this]
      (go
        (let [thread (<! (update-thread! app))]
          (start-thread-subscription! (:id thread) app owner))))

    om/IWillUpdate
    (will-update [this next-props next-state]
      (let [last-props (om/get-props owner)]
        (when (not= (:route-data next-props) (:route-data last-props))
          (stop-thread-subscription! owner)
          (go
            (let [thread (<! (update-thread! app))]
              (start-thread-subscription! (:id thread) app owner))))))

    om/IWillUnmount
    (will-unmount [this]
      (stop-thread-subscription! owner))

    om/IRender
    (render [this]
      (let [autocomplete-users (:autocomplete-users thread)]
        (html
          (if thread
            [:div
             [:h1 (:title thread)]
             [:ol.list-unstyled
              (for [post (:posts thread)]
                (om/build post-component
                          {:post post :autocomplete-users autocomplete-users}
                          {:react-key (:id post)}))]
             (om/build post-form-component {:init-post (models/empty-post (:id thread))
                                            :autocomplete-users autocomplete-users
                                            :after-persisted (fn [post reset-form!]
                                                               (reset-form!)
                                                               (update-post! app post))})]
            [:div]))))))
