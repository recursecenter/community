(ns community.components.thread
  (:require [community.util :refer-macros [<? p]]
            [community.api :as api]
            [community.models :as models]
            [community.partials :as partials]
            [community.routes :as routes]
            [community.components.shared :as shared]
            [om.core :as om]
            [sablono.core :refer-macros [html]]
            [cljs.core.async :as async])
  (:require-macros [cljs.core.async.macros :refer [go go-loop]]))

(defn post-form-component [_ owner {:keys [before-persisted after-persisted init-post cancel-edit]}]
  (reify
    om/IDisplayName
    (display-name [_] "PostForm")

    om/IInitState
    (init-state [this]
      {:post init-post
       :c-post (async/chan 1)
       :form-disabled? false
       :errors #{}})

    om/IWillMount
    (will-mount [this]
      (let [{:keys [c-post]} (om/get-state owner)]
        (go-loop []
          (when-let [post (<! c-post)]
            (when before-persisted
              (before-persisted post))
            (try
              (let [new-post (<? (if (:persisted? post)
                                   (api/update-post post)
                                   (api/new-post post)))]
                (om/set-state! owner :form-disabled? false)
                (om/set-state! owner :errors #{})
                (after-persisted new-post
                                 #(om/set-state! owner :post (models/empty-post (:thread-id new-post)))))
              (catch ExceptionInfo e
                (om/set-state! owner :form-disabled? false)
                (let [e-data (ex-data e)]
                  (om/update-state! owner :errors #(conj % (:message e-data))))))
            (recur)))))

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
             (let [post-body-id (str "post-body-" (:id post))]
               [:div.form-group
                [:label.hide {:for post-body-id} "Body"]
                (om/build shared/resizing-textarea-component {:content (:body post)}
                          {:opts {:focus? (:persisted? post)
                                  :passthrough
                                  {:id post-body-id
                                   :class "form-control"
                                   :name "post[body]"
                                   :onChange (fn [e]
                                               (om/set-state! owner [:post :body]
                                                              (-> e .-target .-value)))}}})])
             [:button.btn.btn-default {:type "submit"
                                       :disabled form-disabled?}
              (if (:persisted? post) "Update" "Post")]
             (when (:persisted? post)
               [:button.close {:type "button"
                               :onClick cancel-edit}
                "x"])]]])))))

(defn post-component [post owner]
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
            (om/build post-form-component nil
                      {:opts {:init-post (om/value post)
                              :after-persisted (fn [new-post reset-form!]
                                                 (om/set-state! owner :editing? false)
                                                 (doseq [[k v] new-post]
                                                   (om/update! post k v)))
                              :cancel-edit (fn []
                                             (om/set-state! owner :editing? false))}})

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
        (om/update! app :errors #{}))

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
      (update-thread! app)
      (start-thread-subscription! (:id route-data) app owner))

    om/IWillUpdate
    (will-update [this next-props next-state]
      (let [last-props (om/get-props owner)]
        (when (not= (:route-data next-props) (:route-data last-props))
          (stop-thread-subscription! owner)
          (update-thread! app)
          (start-thread-subscription! (:id (:route-data next-props)) app owner))))

    om/IWillUnmount
    (will-unmount [this]
      (stop-thread-subscription! owner))

    om/IRender
    (render [this]
      (html
        (if thread
          [:div
           [:h1 (:title thread)]
           [:ol.list-unstyled (om/build-all post-component (:posts thread) {:key :id})]
           (om/build post-form-component nil
                     {:opts {:init-post (models/empty-post (:id thread))
                             :after-persisted
                             (fn [post reset-form!]
                               (reset-form!)
                               (update-post! app post))}})]
          [:div])))))
